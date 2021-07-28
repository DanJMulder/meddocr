# meddocr
A Shiny app that creates markdown templets for clinical encounters
by Daniel Mulder, MD, PhD

## Background
Documentation has become a major component of clinical work, especially with the introduction of electronic health records (EHRs).
The importance of properly documenting a patient encounter is important to physicians for many reasons:
- Interprofessional Communication
- Medicolegal Protection
- Compensation
The value of documentation in clinical practice is so high that it, unfortunately, has begun to overshadow direct patient communication.

Clinicians often create many de novo reports per day. Many reports include components that contain repeated text.
Recently, some highly sophisticated (and highly expensive) EHRs have made it possible for templates to be created for clinical documentation.
Customization through small repeating modules (such as an oft repeated physical exam process) and full document templates improves documentation efficiency and decreases input errors.
The ability to create high fidelity modules and templates in EHRs is currently limited to a small number of extremely costly EHR programs.
Additionally, creation of modules and templates takes time and uptake is often poor.
Most EHRs lack the ability to accept sophisticated input, but instead rely of dictation or scanning of written documents.

This project aimed to create an open source open access template application that can be implemented regardless of EHR input mode.

## Code Overview
Initial implementation requires:
- A local installation of R and RStudio
- Packages: shiny, tidyverse, glue, lubridate, officeR, readxl
- Running the script (a single .R file) and calling the "meddocr()" function (which does not use any arguments)

## Initial Set Up
1. [Links to R and RStudio to install]
2. Install the requisite packages by inputing *** into the console section in R studio
3. Download the repository
4. Once the packages are installed, open the meddocr.R file in RStudio, run the script by presssing "source" (or *** cntrl alt enter?)
5. Run the function by calling "meddocr()" at the command line

## Running the app
Once the initial set up is completed, the app can be run repeatedly
To start the app, open "meddocs.R" and run the script (click the "Run App" button or press command+shift+S on mac or ???+shift+S on windows)
Note: the code in this repository (and the Shiny app contained within) does not transmit information over the internet.
Fill in the available "Patient Data" fields. Note that selecting the "endoscopy" or "foreign body phone call" visit types will automatically cause further actions to appear.
Once all the requisite information has been added for the patient, clicking "Add this patient to the table" will create a table to the right with the information. To add another patient to the table, replace the first patient's data with the next and again click "Add this patient to the table"

Once all the desired patient information is added to the table, click "Create templates for this table" and the Shiny app will create a template clnical note in the form of a .docx file for each patient. The Shiny app creates the templates by by passing the patient information to the specific R markdown '.Rmd' files specified by the visit type for each patient. Under the hood, the app also passes the patient data to the "output_test.csv" table (in order to save the patient table in case the template creation fails, which will then be easier to re-enter from this stage) and also adds the patient data to the "billing_list.csv" table with the appropriate billing code and amount for Ontario's OHIP billing schedule.

## Features
The templates created: [add to this!] are personalized/specific in that they include sections only relevant to the patient's chief complaint, sex, age, location and visit type.
For example, ...

## Creating your own personalized templates
The .Rmd templates in this repository are simplified examples of my own personal markdown documents, thus they are for pediatric gastroenterology patients.
The true power is in editing the example markdown .Rmd files to create templates to suit the user's own needs.
For example, the "endoscopy.Rmd" markdown document contains snippets of text that could easily be edited to work for any proceduralist. The "consult.Rmd" and "follow_up.Rmd" files can be edited to include new cheif complaints and then personalized sections can be created using the if/else statements in the .Rmd files. If this is done, the only change needed beyond changing the .Rmd file itself is changing the list of chief complaint choices on line 40.

## Advantages and Limitations
... this app can be downloaded and personalized as much as desired. A few hours of set up could potentially save hundreds of hours of documentation time over the ensuing years. Setting up the app to output personalized templates that bill the correct codes will require some basic knowledge of R in order to find the sections that can be customized, but the requirement to truly code is minimal as only the clinical text and the objects it is assigned to would need to be edited. The user should be able to create their own templates with basic knowledge of object assignment and conditional statements.
