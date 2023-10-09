Maven/Java project used to test some of the resources in this repository.

## Files

* `pom.xml` - The Maven Project Model build file to run the tests.
* `OracleTests.java` - Tests `../installation/systemdatabase/oracle/*.sql`.
* `PostgresTests.java` - Tests `../installation/systemdatabase/postgresql/seetst-ddl.sql`.
* `MSSQLServerTests.java` - Tests non Azure `../installation/systemdatabase/mssql/*.sql`.

## Prerequisite

This requires JDK 17, a running Docker environment and Maven 3.8 or 3.9.x on the path.

## Run Tests

This is usually executed as a Github Integration test, see `/.github/workflows/maven-verify.yml`.

To manually execute the tests, use:

```
cd tests
mvn verify
```

Special thanks to the https://java.testcontainer.org project.