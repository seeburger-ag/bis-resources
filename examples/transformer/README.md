Sample *BeanShell* script for *SEEBURGER BIS* Component *Transformer*.

## Files

* `sample-transform.bsh` - BeanShell script (wrapped in Java class) demonstrating Transformer's custom script functionality, which allows custom stream processing.
The example script does replace the file with a fixed message.

## Using the sample-transform.bsh example script

Normally you would develop the BeanShell scripts in the Developer Studio as `.bsh.java` files in simplified Java syntax to get the benefit of Syntax Highlighting and Syntax Checking. The Developer Studio then strips the Java class declaration (and the matching brackets (`{ ... }`)). The example script is already prepared and renamed to `.bsh`.

Move the file to `/tmp/sample-transform.bsh` on your <em>Admin Server</em> machine.

Upload the script to <em>resrepo</em> with the following console command:

```
client resrepo:put -f /tmp/sample-transform.bsh /000/scripts/bsh/transformer/sample-transform.bsh
```

The BIS Transformer will search the file relative to the current logical system (in our example 000: `/000/scripts/bsh/...`) or the common logical system (`/ALL/scripts/bsh/...`). 

The script must implement the method execute, as prescribed by the `com.seeburger.components.transformer.ITransformerScript` interface:

```java
public com.seeburger.components.transformer.TransformerScriptResult transform(InputStream, HashMap)
        throws com.seeburger.script.exc.ScriptException;
```

After upload, you can create a new custom process with the Transformer (file content) activity or a Integration Solution Transform activity step and fill the name of the new script into the **scriptFile** property with the relative path `transformer/sample-transform.bsh`.

You can also deploy the script with the help of the Developer Studio, which will generate a deployable ZIP file (and makes the Java/bsh adjustments in the build job).

Deployable ZIPs can be uploaded to the Deployment Manager.


## See Also

Refer to the **BIS Components Guide** manual.<br/>
BeanShell is described here: https://beanshell.github.io/manual/contents.html
