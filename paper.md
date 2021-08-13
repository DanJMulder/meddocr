---
title: 'meddocr: Facilitating clinical documentation for research using R'
tags:
  - R
  - Shiny
  - epidemiology
  - electronic health records
  - mquality improvement
authors:
  - name: Daniel J. Mulder^[corresponding author]
    orcid: 0000-0003-2974-855X
    affiliation: "1"
affiliations:
 - name: Departments of Pediatrics, Medicine, Biomedical and Molecular Sciences, Queen’s University, Kingston, Ontario, Canada
   index: 1
date: 10 August 2021
bibliography: paper.bib
---

# Summary

Biomedical research often relies on patient information obtained from electronic health records (EHRs). However, an EHR’s primary functions are for clinical communication and for medicolegal record-keeping. The primary functions often result in each patient record becoming a collection of innumerable text-based documents with non-standard structure, making text mining challenging and unreliable [@Ford:2016].

Additionally, a wide variety of EHR programs are used in clinical practice, with a broad array of sophistication and customizability. The most advanced EHRs are expensive, closed source environments [@Wencheng:2018]. This fragmentation of medical record structure represents a major barrier to standardizing document structure to facilitate research and data mining.

Despite the non-standardized and siloed form of most clinical documentation, it nearly always exists as plain text data. Thus, an open source open access application, meddocr, was developed using R [@r_citation:2020] and in particular the Shiny application development package.

The application provides a reactive interface that takes a minimal amount of patient data (such as name, date of birth, presenting symptom) and encounter context data (such as if clinic visit or inpatient follow up visit) and creates a semi-standardized document for the clinician to enter relevant information, while preserving structure enough to enable future rapid reliable text mining. A subsequent feature of this process is that the application will also add the demographic and encounter information to a database that will further facilitate organization of reports and filtering of data for research. The application is also designed be locally hosted, to preserve sensitive patient data.

# Statement of need

In order to create patient care records that can be utilized for research, a balance is required between standard document stucture and the freedom to create clear, customized documentation. The challenge of non-standardized records can be overcome by standardizing the input sections and providing pre-written text snippets using an open access application.

# Usage

`meddocr` is available on GitHub and can be run from an RStudio session or run locally in a web browser. The only dependencies are six small R packages, which can be installed using code copied from the `README.md` file.

As a brief example, the user loads the Shiny app and the reactive interface appears. The interface consists of a side panel and main panel with two tabs in the main panel. The main panel is divided into two tabs. The first tab is "Composition", which is displayed by default. The user fills in the available "Patient Data" fields in the sidebar. Note that selecting some options (such the "endoscopy" or "foreign body phone call" visit types) will automatically cause further sidebar input sections to appear.

The information entered in the side panel determines the text imput sections in the main panel. These text sections are filled with text snippets, which are also determined by the information from the side panel. The user edits the note by working with the text snippets found in the textboxes in the first tab of the main panel.

Once the textboxes in the "Composition" tab are filled in to the user's satisfaction, the user navigates to the "Note Preview" tab (at the top of the main panel) to preview the note text. Once they are satisfied with the note text, the "Save Note" button at the bottom of the second tab will save the text to a word document (.docx) for input into any medical record. The user can also choose to click the "Save Encounter to Database" button to save relevant encounter information into a database `encounter_data.csv` that can serve as a patient database for tracking patients for research or data mining. If an `encounter_data.csv` file does not exist in the working directory, meddocr will create one. Verifying the document creation and database functions can be done manually simply by running the app and navigating to the "Save Note" and "Save Encounter to Database" buttons in the second tab and then pressing them, the side panel information is filled in with default values when the app is run, so a sample default .docx report (and database entry) will be created.

# Discussion

Meddocr has been created for use by clinicians when they are documenting patient encounters that will require data extraction in the future. Through semi-standardized document creation, the clinician is given flexibility to document as required, but the document framework is preserved enough to enable rapid, robust evaluation for research. Once customized for a particular clinical trial or patient population, the app can save time for both the clinician (through template-style documentation) and the researcher (thorugh rapid, straightforward data extraction). This app is secure in that it can be run entirely on a local machine without the need for an internet connection. This app is currently being used to create a database of semi-standardized document tracking in inflammatory bowel disease clinical trials at our institution.

# Figures

![Example Encounter](figures/example encounter.png)

# References

