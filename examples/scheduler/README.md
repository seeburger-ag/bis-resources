Sample *BeanShell* scripts for *SEEBURGER BIS Scheduler*.

## Files

* `gate.bsh` - BeanShell script (wrapped in Java class) demonstrating Scheduler's gate functionality, which allows custom logic to skip scheduler executions. In this case it will skip on every first friday of the month.
* `script-listener.bsh` - BeanShell script (wrapped in Java class) demonstrating a Scheduler's Script Listener (onTick() method). The specific sample only extracts some execution details and logs them.

## Using the gate.bsh sample

Normally you would develop the BeanShell scripts in the Developer Studio as `.bsh.java` files in simplified Java syntax to get the benefit of Syntax Highlighting and Syntax Checking. The Developer Studio then strips the Java class declaration (and the matching brackets (`{ ... }`)). The example script is already prepared and renamed to `.bsh`.

Move the file to `/tmp/gate.bsh` on your <em>Admin Server</em> machine.

Upload the script to <em>resrepo</em> with the following console command:

```
client resrepo:put -f /tmp/gate.bsh /000/scripts/bsh/scheduler/gate.bsh
```

The BIS Scheduler will search the file relative to the current logical system (in our example 000: `/000/scripts/bsh/...`) or the common logical system (`/ALL/scripts/bsh/...`). 

The script must implement the method execute, as prescribed by the `com.seeburger.script.IExecutor` interface:

```java
public void execute(InputStream, OutputStream,
                    HashMap, HashMap, OutputStream, String)
    throws com.seeburger.script.exc.ScriptException;
```

After upload, you can add the new script into the **Script Name** field of any Scheduler task with the relative path `scheduler/gate.bsh`.

You can also deploy the script with the help of the Developer Studio, which will generate a deployable ZIP file (and makes the Java/bsh adjustments in the build job).

Deployable ZIPs can be uploaded to the Deployment Manager.

## Using the script-listener.bsh sample

Upload the script (as described above) to `000/scripts/bsh/scheduler/script-listener.bsh` and add a new Task with the Listener Type "ScriptListener". Fill in the **Script Name** `scheduler/script-listener.bsh` and give it a sample string parameter.

This script implements the method `onTick` as prescribed by the `com.seeburger.scheduler.listener.ISchedulerListener` interface:

```java
public void onTick(com.seeburger.scheduler.engine.TickEvent tickEvent)
    throws com.seeburger.scheduler.SchedulerException;
```

## See Also

Refer to the **BIS Masterdata Navigator** online help in the Scheduler section for details. BeanShell is described here: https://beanshell.github.io/manual/contents.html
