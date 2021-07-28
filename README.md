# meddocr
A Shiny app that creates markdown templets for clinical encounters
by Daniel Mulder, MD, PhD

## Background
Documentation has become a major component of clinical work, especially with the introduction of electronic health records (EHRs).
The importance of properly documenting a patient encounter is important to physicians for many reasons:
- Interprofessional Communication
- Medicolegal Protection
- Compensation

The value of documentation in clinical practice is so high that, unfortunately, it has begun to overshadow direct patient communication.

Clinicians often create many de novo reports per day. Many reports include components that contain repeated text. Recently, some highly sophisticated (and highly expensive) EHRs have made it possible for templates to be created for clinical documentation. Customization through small repeating modules (such as an oft repeated physical exam process) and full document templates improves documentation efficiency and decreases input errors. The ability to create high fidelity modules and templates in EHRs is currently limited to a small number of extremely costly EHR programs. Additionally, creation of modules and templates takes time and uptake is often poor. Most EHRs lack the ability to accept sophisticated input, but instead rely of dictation or scanning of written documents.

This project aimed to create an open source open access template application that can be implemented regardless of EHR input mode.

## Initial Set Up Requirements
- A local installation of R and RStudio
- Installed Packages: shiny, tidyverse, glue, lubridate, officeR, readxl

## Running the App
Once the initial set up is completed, the app can be run repeatedly

- To load the app as a function, open "meddocs.R" and source the script (click the "Run App" button or press `command + shift + return` on mac or `control + shift + enter` on windows)
- To run the app, call the `meddocr()` function (which does not use any arguments)

Note: the code in this repository (and the Shiny app contained within) does not transmit information over the internet.

Fill in the available "Patient Data" fields in the sidebar. Note that selecting some options (such the "endoscopy" or "foreign body phone call" visit types) will automatically cause further sidebar input sections to appear. Once all the requisite information has been added for the patient encounter in the sidebar, edit the note by working in the textboxes in the main panel (first tab "Composition", which is displayed by default). Once the textboxes are filled in to your satisfaction, navigate to the "Note Preview" tab (at the top of the main panel) to preview the note text. Once you are happy with the note text, you can click the "Save Note" button to save the note as a word document (.docx) and click the "Save Encounter to Billing Database" button to save the information into a billing table/spreadsheet (billing_data.csv) that is submission ready for Ontario's OHIP billing schedule. If a "billing_data.csv" file does not exist in the working directory, meddocr will create one, then add rows to the spreadsheet for future patient data.

## Overall Script Structure
1. Entire script is packed into a function "meddocr()" that runs without arguments
2. Load required R packages
3. Load text snippets for building a modular patient encounter note
4. Pre-loaded functions (separate from app)
  A. save note data function (savedocxData)
5. UI
  A. Sidebar panel (for entering demographic/visit info)
  B. Main panel
    Tab 1: Editable textboxes that are preloaded with the relevant text snippets (decided by encounter context info from the sidebar)
    Tab 2: 
      Section A: Preview of note output (combining sidebar info + textboxes into minimally formatted note)
      Section B: Save and billing buttons
6. Server
  A. Clinical encounter note creation sections (created depending on the demographic info from the sidebar and the text input in the editable textboxes)
  B. Functions for combining all the note module sections into a single text object
  C. Function for saving the note to a .docx file
  D. Function for saving the encounter billing information to a csv file (will create a new csv file if one does not exist yet)


## Creating your own personalized templates
The text snippets at the top of the meddocr.R script are simplified examples of my own personal snippets, thus they are for pediatric gastroenterology patients. The text snippets can, however, be edited and customized by the user. I suggest starting with an existing chief complaint and using the search function to discover where it is used throughout the script and then creating a new chief complaint and trying to replicate usage. The user will require only basic understanding of R; most importantly: working with strings, lists, and if/else statements. If the customization is performed with the view that the core of the template is the chief complaint then a customized template should be relatively straightforward to add. Detailed customization will require working knowledge of Shiny elements.

## Advantages and Limitations
This app is will always be free. It can be downloaded and personalized as much as desired. A few hours of set up could potentially save hundreds of hours of documentation time over the ensuing years. The app (although it can be run in a browser) is entirely hosted on the user's system and thus no personal health information is transmitted over the internet. This app's immediate utility is limited by its default set up for pediatric gastroenterology practice, but can be customized to any clinical context.
