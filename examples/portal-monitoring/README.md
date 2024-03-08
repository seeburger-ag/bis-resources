Sample *BIS Monitoring* Search Profile configuration.

## Files

* `trade-profile.xml`- XML configuration file for configuring a new sample search profile.
* `trade-en.seenls` - English translations for the profile.
* `trade-de.seenls` - German translations for the profile.


## Using the files

As described in the BIS Monitoring manual you would upload the files into the resource repository (ResRepo).
The following console client commands would be needed if you upload from /tmp (local) directory:

```shell
cd /opt/seeburger/bis
bin/client resrepo:put /tmp/trade-profile.xml 000/monitoring/profiles/Trade/profile.xml
bin/client resrepo:put /tmp/trade_en.seenls   000/adapter/ui/translations/customer/portal/monitoring/trade_de.seenls
bin/client resrepo:put /tmp/trade_de.seenls   000/adapter/ui/translations/customer/portal/monitoring/trade_de.seenls
```

This asumes it is installed into the default logical system `000` and under the custom name "Trade".
The "customer" part of the target resource part should be replaced by the customer specific name (also inside profile.xml).

The content is based on the built-in *standard* profile.

After upload, you get a new search profile "Trade" in the BIS Monitoring.
If you update the files you need to specify the `--force` option to `resrepo:put` command and it might require 10 minutes wait time for the cache to expire.


## See Also

Refer to the **BIS Monitoring** manual in the "**Creating Custom Search Profiles**" section.
