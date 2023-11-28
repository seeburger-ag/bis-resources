/*
 * OracleTests.java
 *
 * created at 2023-10-07 by Bernd Eckenfels <b.eckenfels@seeburger.de>
 *
 * Copyright (c) SEEBURGER AG, Germany. All Rights Reserved.
 */
package com.seeburger.bis6resources.tests;

import static org.junit.jupiter.api.Assertions.*;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Objects;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.Container.ExecResult;
import org.testcontainers.utility.DockerImageName;
import org.testcontainers.utility.MountableFile;
import org.testcontainers.oracle.OracleContainer;

/**
 * Testing the installation/systemdatabase/oracle/*.sql DDL scripts
 * <p>
 * This test will use Oracle Database in Testcontainer to apply the
 * sample scripts and validate that they are in effect.
 */
class OracleTests
{
    static final private String BASE = "../installation/systemdatabase/oracle/";

    static OracleContainer dbContainer = null;

    @BeforeAll
    static void setUpBeforeClass()
        throws Exception
    {
        System.out.println("Starting container...");

        // https://container-registry.oracle.com/ords/
        // DockerImageName name = DockerImageName.parse("container-registry.oracle.com/database/free:23.3.0.0").asCompatibleSubstituteFor("gvenzl/oracle-free");
        DockerImageName name = DockerImageName.parse("gvenzl/oracle-free:latest");

        // we do this here to not hide the fail reason in Initializer Exception
        dbContainer = new OracleContainer(name);

        dbContainer.start();
        System.out.println("done.");
    }

    @AfterAll
    static void afterClass()
        throws Exception
    {
        if (dbContainer != null)
        {
            var tmp = dbContainer;
            dbContainer = null;

            System.out.println("Stopping container...");
            tmp.stop();
            System.out.println("done.");
        }
    }

    @Test
    void testCreateDatabase() throws UnsupportedOperationException, IOException, InterruptedException, SQLException
    {
        // we need to run in PDB and not use OMF, also can use smaller files
        adjustAndTransferFile("create-tbs.sql",
            "-- ALTER SESSION SET CONTAINER=\"PDBSEEBIS\";", "ALTER SESSION SET CONTAINER=\"FREEPDB1\";",
             "SEEDTA DATAFILE SIZE 2G", "SEEDTA DATAFILE 'seedta.dbf' SIZE 20M",
             "SEEIDX DATAFILE SIZE 2G", "SEEIDX DATAFILE 'seeidx.dbf' SIZE 20M",
             "SEELOB DATAFILE SIZE 5G", "SEELOB DATAFILE 'seelob.dbf' SIZE 20M");

        adjustAndTransferFile("create-roles.sql",
            "-- ALTER SESSION SET CONTAINER=\"PDBSEEBIS\";", "ALTER SESSION SET CONTAINER=\"FREEPDB1\";");
        adjustAndTransferFile("create-schema.sql",
            "-- ALTER SESSION SET CONTAINER=\"PDBSEEBIS\";", "ALTER SESSION SET CONTAINER=\"FREEPDB1\";");
        adjustAndTransferFile("create-user.sql",
            "-- ALTER SESSION SET CONTAINER=\"PDBSEEBIS\";", "ALTER SESSION SET CONTAINER=\"FREEPDB1\";");

        executeScript("/ AS SYSDBA", "create-tbs.sql");
        executeScript("/ AS SYSDBA", "create-roles.sql");
        executeScript("/ AS SYSDBA", "create-schema.sql");
        executeScript("/ AS SYSDBA", "create-user.sql");

        // test db owner can login and create a table
        try(Connection c = DriverManager.getConnection(dbContainer.getJdbcUrl(), "seeasdb0", "secret");
            Statement s = c.createStatement(); )
        {
            s.executeUpdate("CREATE TABLE tTest(cTest VARCHAR2(256))");
        }

        // run the grant script and verify it has permission on new table
        adjustAndTransferFile("grant-runtime-user.sql",
            "SEERUN0B", "SEERUN0");

        executeScript("seeasdb0/secret@FREEPDB1", "grant-runtime-user.sql");

        // test runtimew user can login and select the new table
        try(Connection c = DriverManager.getConnection(dbContainer.getJdbcUrl(), "seerun0", "secret");
            Statement s = c.createStatement(); )
        {
            // this also validated the search path finds the table
            s.executeUpdate("SELECT cTest from tTest");
        }
    }

    /** Copy the file(s) from base directory to container /tmp. */
    private void transferFiles(String... files)
    {
        for(String f : files)
        {
            MountableFile mf = MountableFile.forHostPath(BASE + f);
            dbContainer.copyFileToContainer(mf, "/tmp/"+f);
        }
    }

    /** Copy the file from base directory to container by string replacing arguments. */
    private void adjustAndTransferFile(String file, String... replacements) throws IOException
    {
        String content = Files.readString(Paths.get(BASE + file), StandardCharsets.ISO_8859_1);
        int pos = 0;
        while(pos < replacements.length)
        {
            String search = replacements[pos++];
            String replace = replacements[pos++];

            if (!content.contains(search))
            {
                fail("Test setup changed, file " + file + " no longer contains <" + search + ">");
            }

            content = content.replace(search, replace);
        }

        Path dir = Files.createTempDirectory(Paths.get("target"),"ora.");
        Path tmp = dir.resolve(file);
        Files.writeString(tmp, content, StandardCharsets.ISO_8859_1, StandardOpenOption.CREATE);

        MountableFile mf = MountableFile.forHostPath(tmp);
        dbContainer.copyFileToContainer(mf, "/tmp/"+file);
    }

    /**
     * Copy file to container and execute it with sqlplus.
     * <p>
     * After command execution error code and output is checked for errors.
     *
     * @param login user string for sqlplus
     * @param file sql file name in /tmp directory in container
     */
    private void executeScript(String login, String file) throws UnsupportedOperationException, IOException, InterruptedException
    {
        System.out.println("Executing " + file + " as " + login);

        // prepend the container change since we log into root CDB.
        ExecResult r = dbContainer.execInContainer("bash", "-c",
            "sqlplus -s " + login + " < /tmp/" + file);

        String err = Objects.requireNonNullElse(r.getStderr(), "");
        String result = "err: " + err + " out: " + r.getStdout();

        if (r.getExitCode() != 0)
        {
            fail("The script execution of " + file + " returned exit code " + r.getExitCode() + " " + result);
        }

        if (!err.isEmpty() || result.contains("ERROR") ||result.contains("WARN") || result.contains("ORA-"))
        {
            fail("The script execution of " + file + " showed error text " + result);
        }

        //System.out.println(">> result " + result);
    }
}
