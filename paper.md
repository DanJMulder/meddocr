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

Biomedical research often relies on patient information obtained from electronic health records (EHRs). However, an EHR’s primary function is for clinical communication and for medicolegal record-keeping. This primary function often results in each patient’s record becoming a collection of innumerable text-based documents with non-standard structure, making text mining challenging and unreliable {{}}.
Additionally, a wide variety of EHR programs are used in clinical practice, with a broad array of sophistication and customizability. The most advanced EHRs are expensive, closed source environments {{}}. This fragmentation of medical record structure represents a major barrier to standardizing document structure to facilitate research and data mining.
Despite the non-standardized and siloed form of most clinical documentation, it nearly always exists as plain text data. Thus, an open source open access application, meddocr, was developed using R {{R Core Team, 2020}} and in particular the Shiny application development package.
The application provides a reactive interface that takes a minimal amount of patient data (such as name, date of birth, presenting symptom) and encounter context data (such as if clinic visit or inpatient follow up visit) and creates a semi-standardized document for the clinician to enter relevant information, while preserving structure enough to enable future rapid reliable text mining. A subsequent feature of this process is that the application will also add the demographic and encounter information to a simple spreadsheet database that will further facilitate organization of reports and filtering data for research. The application is also designed be locally hosted, to preserve sensitive patient data.

# Statement of need

In order to create patient care records that can be utilized for research, a balance is required between standard document stucture and the freedom to create clear, customized documentation. The challenge of non-standardized records can be overcome by standardizing the input sections and providing pre-written text snippets using an open access application.

# Usage

`meddocr` is available on GitHub and can be run from an RStudio session or run locally in the browser.

As a brief example, the user loads the Shiny app and fills in the available "Patient Data" fields in the sidebar. Note that selecting some options (such the "endoscopy" or "foreign body phone call" visit types) will automatically cause further sidebar input sections to appear. Once all the requisite information has been added for the patient encounter in the sidebar, the user edits the note by working in the pre-defined textboxes in the main panel.

The main panel is divided into two tabs. The first tab is "Composition", which is displayed by default. Once the textboxes in the "Composition" tab are filled in to the user's satisfaction, the user navigates to the "Note Preview" tab (at the top of the main panel) to preview the note text. Once they are satisfied with the note text, the "Save Note" button will save the text to a word document (.docx) and the user can also choose to click the "Save Encounter to Database" button to save the information into a table (encounter_data.csv) that can also serve to create a patient database for research or data mining. If an "encounter_data.csv" file does not exist in the working directory, meddocr will create one, then add rows to the spreadsheet for future patient data.

# Discussion



# Citations



# Figures



# References

