module RightSupport::Net
  module SSL
    # A helper module that provides monkey patch for OpenSSL::SSL.verify_certificate_identity method.
    #
    # To start use it, all you need is to enable it and then register DNS name of the host, which
    # you will trust for sure. This module automatically adds OpenSSL library and reopens
    # verify_certificate_identity method, to change the SSL algorythm of hostname verification.
    module OpenSSLPatch
      class << self
        @@status = false

        def enable!
          return if @@status
          @@status = true

          require 'openssl'
          OpenSSL::SSL.module_exec do
            def verify_certificate_identity(cert, hostname)
              if RightSupport::Net::SSL::OpenSSLPatch.enabled?
                actual_hostname = RightSupport::Net::SSL.expected_hostname
              end
              actual_hostname ||= hostname
              verify_certificate_identity_without_hack(cert, actual_hostname)
            end
            module_function :verify_certificate_identity

            # The original module function of OpenSSL::SSL
            def verify_certificate_identity_without_hack(cert, hostname)
              should_verify_common_name = true
              cert.extensions.each{|ext|
                next if ext.oid != "subjectAltName"
                ext.value.split(/,\s+/).each{|general_name|
                  if /\ADNS:(.*)/ =~ general_name
                    should_verify_common_name = false
                    reg = Regexp.escape($1).gsub(/\\\*/, "[^.]+")
                    return true if /\A#{reg}\z/i =~ hostname
                  elsif /\AIP Address:(.*)/ =~ general_name
                    should_verify_common_name = false
                    return true if $1 == hostname
                  end
                }
              }
              if should_verify_common_name
                cert.subject.to_a.each{|oid, value|
                  if oid == "CN"
                    reg = Regexp.escape(value).gsub(/\\\*/, "[^.]+")
                    return true if /\A#{reg}\z/i =~ hostname
                  end
                }
              end
              return false
            end
            module_function :verify_certificate_identity_without_hack
          end
        end

        def disable!
          @@status = false
        end

        def enabled?
          @@status
        end
      end
    end
  end
end
