Feature: integration print the correct messages

  Scenario: Start PostgreSQL
    Given Database init script
    """
    CREATE TABLE IF NOT EXISTS descriptions (id varchar(10), info varchar(30));
    CREATE TABLE  IF NOT EXISTS measurements (id serial, geojson varchar);

    INSERT INTO descriptions (id, info) VALUES ('SO2', 'Nitric oxide is a free radical');
    INSERT INTO descriptions (id, info) VALUES ('NO2', 'Toxic gas');
    """
    Then start PostgreSQL container

  Scenario: Create transformations integration
    Given Camel-K resource polling configuration
      | maxAttempts          | 200   |
      | delayBetweenAttempts | 2000  |
    Given Camel-K integration property file transformation-test.properties
    When load Camel-K integration Transformations.java
    Then Camel-K integration transformations should be running
    Then Camel-K integration transformations should print Information stored

  Scenario: Integration should store information to the database
    Given SQL query max retry attempts: 10
    Given Database connection
      | driver    | ${YAKS_TESTCONTAINERS_POSTGRESQL_DRIVER} |
      | url       | ${YAKS_TESTCONTAINERS_POSTGRESQL_URL} |
      | username  | ${YAKS_TESTCONTAINERS_POSTGRESQL_USERNAME} |
      | password  | ${YAKS_TESTCONTAINERS_POSTGRESQL_PASSWORD} |
    When SQL query: SELECT COUNT(id) AS NUMROWS FROM measurements
    Then verify column NUMROWS=1

  Scenario: Remove Camel-K integrations
    Given delete Camel-K integration transformations
