/*
 * PostgresTests.java
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
import org.testcontainers.containers.PostgreSQLContainer;

/**
 * Testing the installation/systemdatabase/postgresql/*.sql DDL scripts
 * <p>
 * This test will use PostgreSQL Database in Testcontainer to apply the
 * sample scripts and validate that they are in effect.
 */
class PosgresTests
{
    static final private String BASE = "../installation/systemdatabase/postgresql/";

    static PostgreSQLContainer dbContainer = null;

    @BeforeAll
    static void setUpBeforeClass()
        throws Exception
    {
        System.out.println("Starting container...");

        // we do this here to not hide the fail reason in Initializer Exception
        //DockerImageName name = DockerImageName.parse("postgres:13");
        dbContainer = new PostgreSQLContainer<>(DockerImageName.parse("postgres:13"));

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
        adjustAndTransferFile("seetst-ddl.sql",
            "\\prompt 'Enter new owner - user password: ' owner_pass", "\\set owner_pass 'secret'",
            "\\prompt 'Enter new runtime-user password: ' runtime_pass", "\\set runtime_pass 'secret'");

        executeScript(dbContainer.getUsername(), "seetst-ddl.sql");

        // the URL must point to the new created aspplication database
        String url = dbContainer.getJdbcUrl().replace("/test", "/seetst");
        System.out.println("Testing with App URL " + url);

        // test db owner can login and create a table
        try(Connection c = DriverManager.getConnection(url, "seeasdb0", "secret");
            Statement s = c.createStatement(); )
        {
            s.executeUpdate("CREATE TABLE tTest(cTest VARCHAR(256))");
        }

        // test runtimew user can login and select the new table
        try(Connection c = DriverManager.getConnection(url, "seerun0", "secret");
            Statement s = c.createStatement(); )
        {
            // this also validated the search path finds the table
            try(var r = s.executeQuery("SELECT cTest from tTest");) { /* empty */}
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

        Path dir = Files.createTempDirectory(Paths.get("target"),"pg.");
        Path tmp = dir.resolve(file);
        Files.writeString(tmp, content, StandardCharsets.ISO_8859_1, StandardOpenOption.CREATE);

        MountableFile mf = MountableFile.forHostPath(tmp);
        dbContainer.copyFileToContainer(mf, "/tmp/"+file);
    }

    /**
     * Copy file to container and execute it with psql.
     * <p>
     * After command execution error code and output is checked for errors.
     *
     * @param login user string for psql
     * @param file sql file name in /tmp directory in container
     */
    private void executeScript(String login, String file) throws UnsupportedOperationException, IOException, InterruptedException
    {
        System.out.println("Executing " + file + " as " + login);

         // root is trusted to use any role, testcontainmer does not setup postgres role
        ExecResult r = dbContainer.execInContainer("bash", "-ce",
            "psql -U " + login + " -X -f /tmp/" + file);

        String err = Objects.requireNonNullElse(r.getStderr(), "");
        String result = "err: " + err + " out: " + r.getStdout();

        if (r.getExitCode() != 0)
        {
            fail("The script execution of " + file + " returned exit code " + r.getExitCode() + " " + result);
        }

        if (!err.isEmpty() || result.contains("ERROR") ||result.contains("WARN") || result.contains("FATAL"))
        {
            fail("The script execution of " + file + " showed error text " + result);
        }

        if (!result.endsWith("Reached end of script.\n"))
        {
            fail("The output of " + file + " did not end with end message: " + result);
        }

        //System.out.println(">> result " + result);
    }
}
