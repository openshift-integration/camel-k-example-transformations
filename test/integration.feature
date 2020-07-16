Feature: integration print the correct messages

  Background:
    Given Database connection
      | url       | jdbc:postgresql://mypostgres:5432/example |
      | username  | camel-k-example |
      | password  | transformations |

  Scenario:
    Given integration transformations is running
    Then integration transformations should print Information stored
    When SQL query: SELECT COUNT(id) AS NUMROWS FROM measurements
    Then verify column NUMROWS=1

