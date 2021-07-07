Feature: integration print the correct messages

  Background:
    Given Disable auto removal of Kubernetes resources
    Given load Kubernetes custom resource operatorgroup.yaml in operatorgroups.operators.coreos.com
    Given load Kubernetes custom resource camel-k-subscription.yaml in subscriptions.operators.coreos.com
    Given load Kubernetes custom resource postgres-subscription.yaml in subscriptions.operators.coreos.com

    Given Kubernetes pod labeled with name=postgresql-operator is running
    Given load Kubernetes custom resource database.yaml in databases.postgresql.dev4devs.com
    Given Kubernetes pod labeled with cr=mypostgres is running
    Given Database connection
      | url       | jdbc:postgresql://mypostgres:5432/example |
      | username  | camel-k-example |
      | password  | transformations |
    When execute SQL update
    """
    CREATE TABLE descriptions (id varchar(10), info varchar(30));CREATE TABLE measurements (id serial, geojson varchar);INSERT INTO descriptions (id, info) VALUES ('SO2', 'Nitric oxide is a free radical');INSERT INTO descriptions (id, info) VALUES ('NO2', 'Toxic gas')
    """

  Scenario: Integration transformations store information to the database
    Given Camel-K integration transformations is running
    Then Camel-K integration transformations should print Information stored
    When SQL query: SELECT COUNT(id) AS NUMROWS FROM measurements
    Then verify column NUMROWS=1

