Example **BIS Mapping Designer** project for the *BIS Mapping Language Tutorial*.

## Files

The following lists only the most important files in this project:

* `pom.xml`- Project Object Model and build script (Maven)
* `src/test/messages/SalesData/SalesData.xml` - Test message for the more complex path-expression examples
* `src/main/schemas/SalesData.seexsd` - Sample Data Message Schema
* `src/main/mappings/16_Grouping.seemap` - (One of the) Sample Map using the SampleData schema.


## Using the sample project

You need to import the sample project (directory) into the *BIS Mapping Designer* with the following procedure:

Prerequisite: *BIS Developer Studio* with *BIS Mapping Designer* plugin installed and licensed.

- Start *BIS Developer Studio*, make sure to pick a workspace directory outside of the installation directory.
- Optional: switch or reset the BIS Mapping Designer perspective: **Window -> Perspective -> Open Perspective -> Mapping -> Open** (if Mapping is not in the list use "Other... -> Mapping**).
- Check out this `bis-resources` Git repository into a local directory.
- Use **File -> Import... -> General -> Existing Projects into Workspace** and select the `examples/bismapper/BisMapperLanguage` directory from this check-out as root directory.
- Check the box near project and choose **Finish**.
- In the *Project Explorer* view: unfold `BISMappingLanguage` project, `src/main/mappings` and `src/test/messages/SalesData` folders.
- Open a mapping in the tree by double clicking **src/mappings/16_Grouping.seemap**.
- On the right side, activate the **Mapping Tester** view.
- Drag the testfile `messages/SalesData/SalesData.xml` into the (input) **Message Instance** pane.
- Press **Run** (play button icon) on top of the Mapping Tester to execute this mapping and see the results below in the **Output** pane.

Alternatively, you can also use **File -> Import -> Git -> Projects from Git (with smart import)** and specify `https://github.com/seeburger-ag/bis-resources.git` as your URI.

## See Also

Refer to the **BIS Mapping Designer** (F1) Online-Help and the `BIS_Mapping_Language_Tutorial.pdf` (for example [available](https://community.seeburger.com/t/bis-mapping-designer-short-tutorial-download/1023) on the *SEEBURGER Customer Community*).
