# UK Government organisations

Combining lists of UK Government organisations to make useful CSV files. Automatically updates on the 1st of the month.

## Sources

Data on UK Government organisations is published in a couple of places under the Open Government Licence:

  * [gov.uk/government/organisations](https://www.gov.uk/government/organisations) - this is an HTML page listing <!--GB-GOVUK-->604<!--END GB-GOVUK--> departments, agencies and public bodies. It isn't clear how up-to-date this source is. It has a note if the organisation has a separate website (separate to gov.uk/government/organisations) although these separate website URLs can only be found by following the links and extracting the link from the subsequent webpage. These "real" URLs are saved in [gov.uk_government_organisations-replacement-urls.csv](gov.uk_government_organisations-replacement-urls).
  * [gov.uk/api/organisations](https://www.gov.uk/api/organisations) - this is a paged JSON endpoint that provides more data on <!--GB-GOVUKAPI-TOTAL-->1183<!--END GB-GOVUKAPI-TOTAL--> organisations including some which are no longer operating. It provides an ID that seems to match [GB-GOR](http://org-id.guide/list/GB-GOR) as well as useful metadata about update/closed dates.

It isn't clear if these use the same source or are independently maintained.

## Output

The [get.pl](get.pl) perl script compiles the data from the two sources (HTML/JSON) into several output files. The [gov.uk_government_organisations-replacement-urls.csv](gov.uk_government_organisations-replacement-urls) file can be manually updated to add replacement URLs if gov.uk/government/organisations doesn't know them. The output files are:

  * [gov.uk_api_organisations.json](gov.uk_api_organisations.json) - a JSON blob that contains the results from paging through gov.uk/api/organisations.
  * [gov.uk_api_organisations-augmented.csv](gov.uk_api_organisations-augmented.csv) & [gov.uk_api_organisations-augmented.tsv](gov.uk_api_organisations-augmented.tsv) - CSV/TSV versions of the results from gov.uk/api/organisations augmented with the "real" URL from gov.uk/government/organisations. It doesn't include any organisations with `closed_at` set so has <!--GB-GOVUKAPI-CURRENT-->1070<!--END GB-GOVUKAPI-CURRENT--> organisations.
  * [gov.uk_government_organisations.html](gov.uk_government_organisations.html) - the HTML page from gov.uk/government/organisations.
  * [gov.uk_government_organisations.csv](gov.uk_government_organisations.csv) - a CSV version of gov.uk/government/organisations with the unique URL slug used as an ID along with the title, gov.uk URL, and the "real" URL (which may be identical).
  * [gov.uk_government_organisations-augmented.csv](gov.uk_government_organisations-augmented.csv) & [gov.uk_government_organisations-augmented.tsv](gov.uk_government_organisations-augmented.tsv) - CSV/TSV versions of gov.uk/government/organisations that has had IDs, type, and updated date added. It has <!--GB-GOVUK-->604<!--END GB-GOVUK--> organisations listed.
