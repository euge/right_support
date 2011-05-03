Feature: REST error handling
  In order to enhance app availability and development velocity
  RequestBalancer should consider certain errors as fatal by default
  So careless developers do not cause unexpected behavior when failures occur

  Scenario: resource not found
    Given 4 servers that always respond with 404
    When a client makes a load-balanced request to '/' with timeout 1000
    Then the request should raise ResourceNotFound in less than 3 seconds
    And the request should be attempted once

  Scenario: client-side error
    Given a well-behaved server
    When a client makes a buggy load-balanced request to '/' with timeout 1000
    Then the request should raise ArgumentError in less than 3 seconds
    And the request should be attempted once
