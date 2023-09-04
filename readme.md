# Camel K Transformations Example

This example demonstrates how to transform data with Camel K by showing how to deal with common formats like XML and JSON and how to connect to databases.

![Flux diagram](images/flux_diagram.svg)

We will start by reading a CSV file and loop over each row independently. For each row, we will query an XML API and a database and use all the data collected to build a JSON file. Finally, we will collect and aggregate all rows to build a final JSON to be stored on a database. The final JSON is also a valid [GeoJSON](https://geojson.org/).

## Preparing the cluster

This example can be run on any OpenShift 4.3+ cluster or a local development instance (such as [CRC](https://github.com/code-ready/crc)). Ensure that you have a cluster available and login to it using the OpenShift `oc` command line tool.

You can use the following section to check if your environment is configured properly.

## Checking requirements
**OpenShift CLI ("oc")**

The OpenShift CLI tool ("oc") will be used to interact with the OpenShift cluster.

**Connection to an OpenShift cluster**

You need to connect to an OpenShift cluster in order to run the examples.

We are going to create and use a new project on your cluster to start on a clean environment. This project will be removed at the end of the example.

To create the project, we can use the `oc` tool we just checked:

```
oc new-project camel-transformations
```

Now we can proceed with the next requirement.

**Apache Camel K CLI ("kamel")**

You need to install the Camel K operator in the `camel-transformations` project. To do so, go to the OpenShift 4.x web console, login with a cluster admin account and use the OperatorHub menu item on the left to find and install **"Red Hat Integration - Camel K"**. You will be given the option to install it globally on the cluster or on a specific namespace.

If using a specific namespace, make sure you select the `camel-transformations` project from the dropdown list.
This completes the installation of the Camel K operator (it may take a couple of minutes).

When the operator is installed, from the OpenShift Help menu ("?") at the top of the WebConsole, you can access the "Command Line Tools" page, where you can download the **"kamel"** CLI, that is required for running this example. The CLI must be installed in your system path.

Refer to the **"Red Hat Integration - Camel K"** documentation for a more detailed explanation of the installation steps for the operator and the CLI.

### Optional Requirements

The following requirements are optional. They don't prevent the execution of the demo, but may make it easier to follow.

**VS Code Extension Pack for Apache Camel**

The VS Code Extension Pack for Apache Camel by Red Hat provides a collection of useful tools for Apache Camel K developers,
such as code completion and integrated lifecycle management. They are **recommended** for the tutorial, but they are **not**
required.

You can install it from the VS Code Extensions marketplace.

## 1. Preparing the project

First, make sure we are on the right project:

```
oc project camel-transformations
```

Before you continue, you should ensure that the Camel K operator is installed:

```
oc get csv
```

When Camel K is installed, you should find an entry related to `red-hat-camel-k-operator` in phase `Succeeded`.

You can now proceed to the next section.

## 2. Setting up complementary database

This example uses a PostgreSQL database. We want to install it on the project `camel-transformations`. We can go to the OpenShift 4.x WebConsole page, use the OperatorHub menu item on the left hand side menu and use it to find and install "Crunchy Postgres for Kubernetes". This will install the operator and may take a couple of minutes to install.

Once the operator is installed, we can create a new database using

```
oc create -f test/resources/postgres.yaml
```

We connect to the database pod to create a table and add data to be extracted later.

```
oc rsh $(oc get pods -l postgres-operator.crunchydata.com/role=master -o name)
```

```
psql -U postgres example \
-c "CREATE TABLE descriptions (id varchar(10), info varchar(30));
CREATE TABLE measurements (id serial, geojson varchar);
INSERT INTO descriptions (id, info) VALUES ('SO2', 'Nitric oxide is a free radical');
INSERT INTO descriptions (id, info) VALUES ('NO2', 'Toxic gas');
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgresadmin;
GRANT USAGE, SELECT ON SEQUENCE measurements_id_seq TO postgresadmin;"
```

```
exit
```

Now, we need to find out Postgres username, password and hostname and update the values in the `transformation.properties`.
```
USER_NAME=$(oc get secret postgres-pguser-postgresadmin --template={{.data.user}} | base64 -d)
USER_PASSWORD=$(oc get secret postgres-pguser-postgresadmin --template={{.data.password}} | base64 -d)
HOST=$(oc get secret postgres-pguser-postgresadmin --template={{.data.host}} | base64 -d)
PASSWORD_SKIP_SPEC_CHAR=$(sed -e 's/[&\\/]/\\&/g; s/$/\\/' -e '$s/\\$//' <<<"$USER_PASSWORD")
sed -i '' "s/=camel-k-example/=$USER_NAME/g" transformation.properties
sed -i '' "s/=transformations/=$PASSWORD_SKIP_SPEC_CHAR/g" transformation.properties
sed -i '' "s/=mypostgres/=$HOST/g" transformation.properties
```

## 3. Running the integration

The integration is all contained in a single file named `Transformations.java`.

Additional generic support classes (customizers) are present in the `customizers` directory, to simplify the configuration of PostgreSQL and the CSV dataformat.

We're ready to run the integration on our `camel-transformations` project in the cluster.

Use the following command to run it in "dev mode", in order to see the logs in the integration terminal:

```
kamel run Transformations.java --dev
```

If everything is ok, after the build phase finishes, you should see the Camel integration running and printing the steps output in the terminal window.

**To exit dev mode and terminate the execution**, hit `ctrl+c` on the terminal window.

> **Note:** When you terminate a "dev mode" execution, also the remote integration will be deleted. This gives the experience of a local program execution, but the integration is actually running in the remote cluster.

To keep the integration running and not linked to the terminal, you can run it without "dev mode", just run:

```
kamel run Transformations.java
```

After executing the command, you should be able to see it among running integrations:

```
oc get integrations
```

An integration named `transformations` should be present in the list, and it should be in status `Running`. There's also a `kamel get` command which is an alternative way to list all running integrations.

> **Note:** the first time you've run the integration, an IntegrationKit (basically, a container image) has been created for it and
> it took some time for this phase to finish. When you run the integration a second time, the existing IntegrationKit is reused
> (if possible) and the integration reaches the "Running" state much faster.

Even if it's not running in dev mode, you can still see the logs of the integration using the following command:

```
kamel log transformations
```

The last parameter ("transformations") is the name of the running integration for which you want to display the logs.

**To terminate the log stream**, hit `ctrl+c` on the terminal window.

Closing the log does not terminate the integration. It is still running, as you can see with:

```
oc get integrations
```

> **Note:** Your IDE may provide an "Apache Camel K Integrations" panel where you can see the list of running integrations and also open a window to display the logs.

## 4. Uninstall

To clean up everything, execute the following command which will remove the project from OpenShift and drop all resources related to it.

```
oc delete project camel-transformations
```
