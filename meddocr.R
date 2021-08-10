    ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
    ##   Shiny App for meddocs - clinical note creation from modular templates    ##
    ##   Written by Daniel Mulder, April-May 2021                                 ##
    ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##


## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

# OVERALL SCRIPT STRUCTURE
  # 1. Load required R packages
  # 2. Load text snippets for building a modular patient encounter note
  # 3. Pre-loaded functions (separate from app)
  #   A. save note data function (savedocxData)
  # 4. UI
  #   A. Sidebar panel (for entering demographic/visit info)
  #   B. Main panel
  #     Tab 1: Editable textboxes that are preloaded with the relevant text snippets (decided by encounter context info from the sidebar)
  #     Tab 2: 
  #       Section A: Preview of note output (combining sidebar info + textboxes into minimally formatted note)
  #       Section B: Save and billing buttons
  # 5. Server
  #   A. Clinical encounter note creation sections (created depending on the demographic info from the sidebar and the text input in the editable textboxes)
  #   B. Functions for combining all the note module sections into a single text object
  #   C. Function for saving the note to a .docx file
  #   D. Function for saving the encounter billing information to a csv file (will create a new csv file if one does not exist yet)

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

## Preamble
# This script does not constitute medical advice and is only to be used for the purposes of learning or preparing personal templates
# This script contains no real medical information, any information contained within is fictional example information
# The aim of this script is to include more sections/text in general, since it is much easier to delete than add sections
  
# Load required packages ----
library(shiny) # for interactive web application framework
library(tidyverse) # for basic data organization
library(glue) # for gluing together text
library(lubridate) # for creating/parsing date objects
library(officer) # for saving notes to office formats
library(readxl) # for working with xlsx files


# Load text modules ----

  # Text Snippets and lists that can be loaded shiny app
  
  # Lists ----
  
    fields <- c("mrn",
                "patient_name",
                "hpi_saved_text",
                "dob",
                "sex",
                "visit_type",
                "location",
                "chief_complaint",
                "scope_type",
                "foreign_body_type",
                "foreign_body_symptoms",
                "foreign_body_location")
    
    chief_complaints_list <- c("abdominal pain",
                               "constipation",
                               "pancreatitis",
                               "choledocholithiasis",
                               "abnormal liver tests",
                               "upper GI symptoms",
                               "GI bleed",
                               "bloody diarrhea",
                               "neonatal cholestasis",
                               "possible celiac disease",
                               "foreign body ingestion",
                               "infant feeding difficulties",
                               "failure to thrive",
                               "IBD exacerbation",
                               "foreign body ingestion",
                               "generic")
    
    visit_types_list <- c("new", "follow up", "endoscopy", "phone call")
    
    endoscopy_types_list <- c("NA",
                              "Upper Endoscopy",
                              "Upper Endoscopy and Colonoscopy",
                              "Colonoscopy",
                              "Upper Endoscopy Foreign Body Removal")
    
    foreign_body_types_list <- c("NA",
                                 "button battery",
                                 "magnets",
                                 "sharp",
                                 "food impaction",
                                 "coin",
                                 "long object",
                                 "absorptive object")
    
  # HPI Snippets ----
  
    hpi_text <- "[brief narrative]
    Onset - ***; Location - ***; Duration - ***; Character - ***; Aggravating - ***; Alleviating - ***; Associated - ***; Radiation - ***; Timing - ***; Severity - ***; Previous - ***;
    Fullness - ***
    Relationship to meals - ***
    Relationship to BMs - ***
    Relationship to menses - ***
    Stressors/relationship to stressors - ***"
    
    hpi_neonatal_cholestasis <- "Maternal History: Age - ***; GTPAL - ***; Medical conditions - ***.
    Pregnancy History: Bloodwork in pregnancy - ***serologies; GBS status - ***; Ultrasounds - ***; Sicknesses - especially ***cholestasis or fatty liver; Medications - ***.
    Birth History: Gestation at birth - ***; Type of labour - ***; Instrumentation - ***; Birth weight - ***; Blood groups - ***; Resuscitation - ***, Apgars ***.
    NICU: Stool with in *** h of life.
    Exposures: Alcohol - ***; Drugs/substances (including IV drugs) - ***; Medications/herbals/mushrooms - ***; Travel - ***; Sick contacts - ***."
    
    ibd_background <- "IBD History:
    Disease - ***
    Location: ***
    Diagnosis Date: - ***
    Paris Classification: A L B G or E S. 
    Induction Therapy - ***
    Complications - *** (eg, fistulae, perianal disease, extra-intestinal manifestations)
    Last endoscopy - ***
    Last MRE - ***
    Last PCDAI/PUCAI - ***
    Last TDM - ***
    Last fecal calprotectin - ***
    Current Therapy: ***"

  # ROS Snippets ----
      
    general_ros <- "General - *** energy; *** fevers, weight loss/gain, night sweats, rashes"
    
    infant_feeding_ros <- "Feeding History:
    Type - exclusive breastfeeding; formula *** mixed to concentration ***
    Formula preparation - ***
    Feed Frequency - *** (overnight ***)
    Volume - ***
    Thus - receives *** kcal/kg/day giving a PO TFI of *** mL/kg/day
    Duration of feeds - ***
    Qualitative assessment of supply - ***
    Events during or following feeds - ***, ***Sandifer posturing"
    
    upper_gi_ros <- "Upper GI - *** [nausea/vomiting, dysphagia/odynophagia, aphthous ulcers, emesis]"
    
    eim_ros <- "Extraintestinal Manifestations of IBD - *** fever, red sore eyes, mouth sores, rashes, arthralgias"
    
    eoe_ros <- "Difficulty swallowing solids: ***
    Difficulty swallowing liquids: ***
    Pain with swallowing solids: ***
    Pain swallowing liquids: ***
    Food sticking in throat: ***
    Difficulty swallowing soft, sticky foods (e.g. white bread): ***
    Chest or retrosternal pain: ***
    Abdominal pain or dyspepsia: ***
    Needs to drink a lot of water when eating: ***
    Vomiting: ***
    Atopy: ***"
    
    diet_recall_ros <- "24h dietary recall - *** [if toddler, juice/milk intake]"
    
    stooling_ros <- "Stooling - *** [diarrhea, melena, hematochezia, steatorrhea]"
    
    gu_ros <- "Genitourinary - *** [if constipated, incontinence, UTIs, urine stream abnormalities] [if female, menarche/menses, pregnancy possibility] [if fever, dysuria, foul smelling urine]"
    
    neuro_ros <- "Neurologic - *** [weakness, back pain, abnormal gait]"
    
    id_ros <- "ID - recent infectious symptoms (fever, coryza, etc), travel, sick contacts, sick pets, water source, high risk foods, foods no one else ate, antibiotics"
    
    liver_ros <- "Liver - jaundice *** , scleral icterus *** , pale stools *** , dark urine *** , pruritus ***"
    
    celiac_ros <- "Nausea, vomiting
    Dermatitis herpetiformis (vs urticaria)
    Dental enamel defects
    Short stature
    Failure to thrive
    Fractures
    Iron deficiency
    Anemia
    Osteoporosis
    Elevated liver enzymes
    Arthritis
    Aphthous ulcers
    Amenorrhea
    Diarrhea
    Constipation"
    
    bleed_ros <- "Bleeding ROS:
    Red foods - ***
    Epistaxis - ***
    Iron supplements
    Pepto-bismol or other bismuth containing preparations - ***
    Hematuria - ***
    Hematochezia - ***"
    
    ibd_ros <- "Nausea/vomiting: yes***no
    
    Tenesmus: yes***no
    Urgency: yes***no
    Incontinence: yes***no
    
    Arthralgia: yes***no
    Arthritis: yes***no
    Uveitis: yes***no
    Oral ulcers: yes***no
    EN/PG: yes***no
    Fever: yes***no
    
    Perianal pain: yes***no
    Perianal discharge: yes***no
    
    School days missed in last week: 
    
    Other illness: yes***no"
    
    ros_text <- paste(general_ros, upper_gi_ros, diet_recall_ros, stooling_ros, id_ros, gu_ros, neuro_ros, sep = "\n")

  # PMHx Snippets ----
      
    young_pmhx <- "Pregnancy - ***
    Birth - Born at *** (term?), BW *** g (AGA?), resuscitation?, passed meconium *** [within first 48 hol?]
    Since Birth - *** diagnoses, *** admissions, *** surgeries"
    
    older_pmhx <- "Since Birth - *** diagnoses, *** admissions, *** surgeries"
  
  # Social Hx Snippets ----
      
    social_hx <- "Lives in *** with ***; Grade *** (or daycare)"
    
    heads_hx <- "Lives in *** with ***;
    Interviewed alone, confidentiality reviewed;
    Home - ***;
    Eating - ***;
    Activity - ***;
    Drugs - ***;
    Depression/Mood/Suicidality - ***;
    Sexuality - ***;
    Safety - ***."
      
  # Fam Hx Snippets ----
    
    gi_famhx <- "Parents - ***
    Siblings - ***
    Ethnicity ***
    *** known consanguinity.
    *** history of IBD, autoimmune disease (lupus, rheumatic disease, thyroid disease), celiac disease, or cystic fibrosis."
    
    liver_famhx <- "Parents - ***
    Siblings - ***
    Ethnicity ***
    *** known consanguinity.
    *** history of liver disease, liver transplant, cystic fibrosis, or metabolic syndromes."
    
    pancreatitis_famhx <- "Parents - ***
    Siblings - ***
    Ethnicity ***
    *** known consanguinity.
    *** history of pancreatitis, celiac disease, cystic fibrosis, thyroid disease or autoimmune disease."
    
    eoe_famhx <- "Parents - ***
    Siblings - ***
    Ethnicity ***
    *** known consanguinity.
    *** history of allergies, asthma, eczema."
  
  # PEx Snippets ----
    
    general_pex <- "Vitals - heart rate *** , blood pressure *** , RR *** , SpO2 *** % on room air?, temperature ***.
    Growth - height *** (*** percentile), weight *** (*** percentile), BMI *** (*** percentile).
    General - *** alert and interactive, no pallor, no scleral icterus (rashes?) (clubbing?)"
    
    heent_pex <- "HEENT - *** neck/thyroid masses or enlargement?, oral lesions?"
    
    abdo_pex <- "Abdo - *** normal bowel sounds, soft and nontender with no masses and no hepatosplenomegaly [Carnett sign]"
    
    liver_pex <- "Abdo - *** normal bowel sounds, soft and nontender with no masses. Liver is palpable *** cm below the costal margin in the midclavicular line, liver span is *** cm, spleen is palpable about *** cm below the right costal margin"
    
    perianal_pex <- "Perianal inspection (supervised by ***) - unremarkable, normally placed anus with no skin tags, no fissures, no scars and with no sacral dimple [DRE only if unclear dx, to clarify diagnosis]"
    
    neuro_msk_pex <- "Neuro/MSK - spine inspection *** with *** skin abnormalities or palpable defects. lower extremity tone, strength, and patellar deep tendon reflexes ***."

  # Investigations Snippets ----
    
    inv <- "No investigations available at this time***
    Labs - ***;
    Imaging - ***;
    Endoscopy - ***"

  # Impression Snippets ----
    
    impression_generic <- "[one line summary of H&P & investigations].
    Pertinent positives - ***
    Pertinent negatives - ***
    
    There is a past medical history of *** .
    Red flags include *** 
    Growth has been *** "
    
    impression_neonatal_cholestasis <- "There *** is/not a component of transaminitis. The stools have been *** pigmented/acholic. There are presently *** no signs of encephalopathy. The child is *** feeding and growing well and clinically *** stable."
    
    impression_gi_bleed <- "Suspicious/likely*** upper***lower bleeding. Hemodynamically ***. Hemoglobin ***. There is *** history or signs to suggest liver disease or portal hypertension.
    The first step in management of acute GI bleeding is stabilization, with a focus on blood transfusion. Usually, active GI bleeding in this situation stops on its own. Endoscopy is usually used as a diagnostic tool 24-48 h after presentation and is uncommonly used for intervention."
    
    impression_choledocholithiasis <- "The CBD is/not >=6 mm. There *** does/not appear to be a component of pancreatitis. Acute cholangitis is *** unlikely given lack of Charcot's triad (fever, RUQ pain, jaundice) and leukocytosis."
    
    impression_abnormal_liver_tests <- "The pattern of labs points to a hepatocellular/cholestatic cause. Liver synthetic function is preserved."
    
    impression_upper_gi_symptoms <- "There is***not a history of atopy."
    
    impression_bloody_diarrhea <- "There is/not a family history of IBD."
    
    impression_text <- "[disease_specific_impression]"

  # Assessment Snippets ----
    
    assessment_abdominal_pain <- "The differential diagnosis in this situation remains broad, and includes:
    - Non-GI causes: MSK, genito-urinary (including pregnancy), uro-renal, psychosocial
    - GI causes: functional abdominal pain, constipation, celiac disease, hypothyroidism related GI pain, inflammatory GI disease, allergic GI disease, chronic GI infection (such as H pylori)
    - Hepatobiliary or pancreatic causes"
    
    "In terms of etiology, the differential diagnosis at this time is broad and includes TPN cholestasis, infection/sepsis, biliary obstruction (including biliary atresia), Alagille syndrome, metabolic conditions, gestational alloimmune liver disease, cystic fibrosis and idiopathic neonatal hepatitis."
    
    assessment_neonatal_cholestasis <- "The **critical/time-sensitive** differential diagnosis of neonatal cholestasis that should be addressed immediately are:
    - infection/sepsis (especially UTI)
    - biliary atresia
    - panhypopituitarism,
    - galactosemia, and
    - tyrosinemia"
    
    assessment_non_blood_diarrhea <- "Potential causes include diet/Toddler's diarrhea, infection, inflammation, and allergy."
    
    assessment_pancreatitis <- "Often the etiology of the first episodes of pancreatitis is unclear and does not become evident. Potential causes include obstruction, infection, trauma, toxins (including drugs), and genetic mutations [work up if >1 episode]."
    
    assessment_abnormal_liver_tests <- "At this point, the differential diagnosis is broad, including toxins/drug reaction, infection (especially viral hepatitis), autoimmune disease, metabolic disease (such as Wilson's disease), vascular compromise, and infiltrating mass."
    
    assessment_possible_celiac_disease <- "The differential diagnosis includes celiac disease, allergic-type enteropathy, inflammatory bowel disease, ***."
    
    assessment_upper_gi_symptoms <- "The differential diagnosis includes GERD, eosinophilic esophagitis, H pylori or other chronic infectious agent (esp Candida esophagitis), functional upper GI disease, an anatomic abnormality (such as a mass or malrotation), or a motility disorder (such as achalasia). Inflammatory conditions of the esophagus can lead to strictures that can cause this type of symptoms."
    
    assessment_gi_bleed <- "The differential diagnosis includes [swallowed maternal blood, epistaxis, substance that resembles blood], esophagitis/gastritis, peptic ulcer, pill/foreign body-related, variceal bleeding (less likely given lack of history suggestive of liver disease)."
    
    assessment_bloody_diarrhea <- "The differential diagnosis includes infections (in particular, bacterial gastroenteritis, C difficile colitis, or CMV/EBV), inflammation (in particular, inflammatory bowel disease), and allergic-type conditions."
    
    assessment_text <- " "

  # Plan Snippets ----
    
    plan_text <- "We discussed
    - the most likely diagnoses +/- prognosis
    - next steps/investigations (which I have arranged/will arrange)
    - treatment
    - diet discussion for all patients"
    
    abdominal_pain_plan <- "- I reviewed the benign nature and initial options including 1) probiotics, 2) increased soluble fibre and other dietary modification and 3) cognitive behavioral therapy.
    - [If alarm findings:]
    - Stool - guaiac +/- calprotectin +/- O&P, +/- C&S, +/- H pylori stool antigen (or urea breath test)
    - Bloodwork - CBC, ESR, CRP, lytes, BUN, Cr, glucose, AST, ALT, Alk Phos, GGT, total bilirubin, direct bilirubin, albumin, lipase, tTG, IgA
    - Urinalysis, urine beta-hCG (if female)"
    
    constipation_plan <- "- Education - explained physiology/process of chronic constipation (stool harder, rectum stretched), positive/hope, PEG quite safe in usual doses (trace absorbed, PEG not addictive, PEG will not make bowel lazy)
    - Behaviour - routine toilet sitting 3-10 min 1-2 times per day (best within 1 hour after meals and in am), ensure feet supported (so can valsalva), no punishment (instead praise and reward), consider diary with Bristol ratings, physical activity can be recommended but role unproven
    - Medication - PEG 0.4-1 g/kg/day in drink of choice (occasional abdo pain, bloating, flatulence, loose stools), titrate to response (personalized dose), continue for at least 6 months, wean very gradually (still titrating to stools)
    - If impacted - then start with disimpaction (first line is PEG 1-1.5 g/kg/day for 3-6 days, max 100 g per day, alternative is once per day enema for 3-6 days, oral > rectal but can try one or both, may need to admit if extremely large volumes to give via NG), then maintenance as above
    - Diet - include sorbitol (prune, pear, apple), ensure adequate fibre 0.5 mg/kg/day (to max 35 g), ensure adequate fluid intake
    - Investigations - usually none indicated, first line if major push from caregiver, can have do 72 h intake diary"
    
    neonatal_cholestasis_plan <- "- Treat elevated INR around 1.5-2.0 or greater with vitamin K IV for at least 3 days
    - Follow liver enzymes and synthetic function daily - INR, albumin, total bilirubin, direct bilirubin, +/- ammonium, AST, ALT, ALK, GGT
    - In the presence of confirmed neonatal cholestasis, we recommend the following tier 1 work up:
    - Mandatory initial investigations, to be done today:
    - Abdominal ultrasound; Urine: culture, reducing substances, succinylacetone;
    - Bloodwork: alpha-1-antitrypsin, galactose-1-phosphate uridyl transferase (aka GALT testing), thyroid function (TSH, T4) and INR
    - Confirm newborn screen negative for galactosemia and tyrosinemia
    _ If possible, please add the following, besides the previously suggested,19 if not already ordered:
    _ Serum/blood: CBC, INR, PTT, AST, ALP, GGT, total bilirubin, direct bilirubin, albumin, calcium, phosphate, electrolytes, creatinine, cholesterol, ammonia, plasma amino acids, cortisol, AFP, TORCH, blood culture;
    _ Urine: succinylacetone, organic acids, UA, CMV;
    _ Microbiology Serology: toxoplasmosis, rubella, HSV, CMV;
    _ Imaging: HIDA, x-ray spine;
    _ Consults: Ophthalmology (for ?posterior embryotoxon), cardiology if murmur
    _ [Follow liver enzymes and synthetic function at least twice a week (qMon and Thurs): INR, albumin, total bilirubin, direct bilirubin, ammonium, AST, ALT, ALK, GGT]"
    
    possible_celiac_disease_plan <- "- Upper endoscopy with biopsy for celiac disease
    - We discussed that this child must remain on a gluten containing diet until the endoscopy equal to at least 3-15 g of gluten per day (eg, 1-2 cookies or 1 slice of bread). [DGP if <2 yo]"
    
    choledocholithiasis_plan <- "- Repeat labs in morning (esp liver enzymes, liver function, amylase, lipase) and daily
    - Start IV with admission labs
    - Monitor temperature
    - Pain control with ibuprofen (and morphine if unable to control with ibuprofen)
    - ***Ursodiol 10 mg/kg/day divided bid
    - ***NPO overnight
    - If fever, blood culture and start IV antibiotics (ampicillin, gentamycin, metronidazole to cover enteric flora)
    - Repeat AUS in house in am [if concerns/confusion]
    - Will arrange urgent ERCP; if febrile or clinically deteriorating, we will need to do emergently"
    
    infant_feeding_difficulties_plan <- "If <6 months old - medication only after verifying formula preparation - if exclusively breastfed then consider could be normal stool pattern - if repeated difficulty, can try 2-4 weeks of hypoallergenic formula - the usual constipation algorithm doesn't really apply, don't forget to consider Hirschsprung's"
    
    failure_to_thrive_plan <- "- Full GI FTT profile - CBC/diff, CRP, ESR, lytes, extended lytes, VBG, glucose, Cr, urea, albumin, ferritin, transferrin saturation, liver enzymes x4, liver function tests x3 (also ammonia if infant), total immunoglobulins, tTG-IgA (and total IgA level and anti-DGP if <2 yo), TSH, urinalysis, stool culture, stool virology, and stool O&P
    - Abdo U/S
    - 72 h dietary diary with our RD to review - we may need to work together to change feeding plan, concentrate formula
    - The usual approach to reflux is: PPI (if NG, can ensure adequate acid blockade of gastric aspirate pH of >=4 for 24h) for 1-2 weeks then adding domperidone for 1-2 weeks (during which time the child should have an ECG to establish baseline QTc interval that is safe before starting and then weekly ECGs for the initial weeks) then adding NJ or NG or cisapride (which the primary team applies for special access for and also needs ECG monitoring similar to domperidone)
    - [Then next step in the FTT work up is: sweat chloride, fecal elastase, vitamin levels, fecal calprotectin, bone age)]
    - Consider if this child would benefit from NG feeding, NJ feeding or a G or GJ tube"
    
    gi_bleed_plan <- "- Recommend gen peds team admit for stabilization/monitoring
    - Start IV PPI infusion if hemodynamic concerns (start with bolus, also give bolus if increasing the dose) *** if using octreotide, it takes precedence over PPI if concern for variceal hemorrhage, but should have both if at all possible
    - Close monitoring of hemodynamic status
    - Only stop feeds and make NPO (if vomiting or if going for procedure)
    - Urgent CXR/AXR [to identify any radio-opaque foreign body] and abdo U/S [esp to identify mass lesions or evidence of liver disease/varices]
    - Labs - CBC and diff, type and screen, INR, PTT, CBC, VBG, lactate, ESR, CRP, lytes, extended lytes, urea, Cr, glucose, AST, ALT, Alk Phos, GGT, total bilirubin, direct bilirubin, ammonia x1, albumin, amylase, lipase, tTG, total IgA
    - [Stool - test for infections if diarrhea]"
    
    abnormal_liver_tests_plan <- "- Treat elevated INR around 1.4 or greater with vitamin K IV - 5 mg if less than about 8 yo or else 10 mg (1 mg in an infant) - for at least 3 days
    - Follow liver enzymes daily until decreasing steadily x2 then q3 days
    - Further work up: 
    - CK
    - Acetaminophen level
    - LDH
    - A1AT
    - TSH, free T4
    - Lipid profile
    - Transferrin saturation
    - tTG-IgA and total IgA
    - Ceruloplasmin (RO Wilson only if 4yo or more)
    - CBC with differential
    - 8 am cortisol, ACTH level
    - Urine toxin screen, BhCG
    - HAV, HBV, HCV, HDV, HEV serology
    - CMV, EBV, HSV, HHV6 serology
    - ANA, AntiSMA, antiLKM, AMA, total IgG, IgG subclasses, total protein, protein gap
    - Abdo ultrasound with liver dopplers"
    
    bloody_diarrhea_plan <- "- Bloodwork - CBC/diff, CRP, ESR, albumin, lytes, extended lytes, urea, Cr, glucose, AST, ALT, Alk phos, GGT, total bilirubin, direct bilirubin, amylase, lipase, tTG-IgA, blood culture (if fever), VZV IgG, CMV/EBV serology, HBsAg, antiHBs, CGD testing, iron studies if anemia
    - PPD to be placed ASAP (delays in placement can delay therapy), CXR (to rule out TB in case of immediate need for immunosuppression)
    - Abdominal ultrasound
    - Rule out infection then plan for upper endoscopy and colonoscopy with biopsies
    - If going for colonoscopy, clean out would involve: on the day prior to the procedure have a light breakfast then to take only clear fluids (no reds, no blues though) until the procedure is done the next day, then take 1*** sachet of PicoSalax dissolved in 150 mL of cold water around lunchtime, then to drink 500 mL of water per hour for 4 hours, then a second *** sachet of PicoSalax (+ 2 L of water the same as the first dose) at least 6 h later, then on the morning of the procedure, should be reassessed for complete clean out (stool should be clear or yellow-clear liquid without sediment) and potentially could have a 3rd dose of PicoSalax in the same fashion as before or a normal saline enema (10-15 mL/kg up to 300 mL PR)
    - No NSAIDs, no opioids please (prefer frequent hot packs and acetaminophen)
    - If clinical deterioration, will be important to consider toxic megacolon, which should be investigated immediately with an abdo x-ray
    - Acute severe colitis patients should receive prophylactic anticoagulation due to the risks of devastating thrombotic events outweighing the minimal risk of increased bleeding
    - Therapy can be started if IBD visually confirmed on endoscopy (and when steroids or biologics, when PPD is negative after at least 48 h)
    - If IBD confirmed, will eventually require MR-enterography"
    
    ibd_exacerbation_plan <- "- Start IV/PO steroids or EEN or IFX
    - Hold 5-ASA in hospital due to risk of toxic megacolon [if UC]
    - Stool infectious studies
    - Bloodwork - CBC, ESR, CRP, A-1-AGP, lytes, BUN, Cr, glucose, AST, ALT, Alk Phos, GGT, total bilirubin, direct bilirubin, albumin, amylase, lipase, tTG, IgA, blood culture
    - Urinalysis, urine beta-hCG
    - Abdominal ultrasound
    - No NSAIDs, no opioids please (prefer frequent hot packs and acetaminophen)
    - If clinical deterioration, will be important to consider toxic megacolon, which should be investigated immediately with an abdo x-ray
    - Acute severe colitis patients should receive prophylactic anticoagulation due to the risks of devastating thrombotic events outweighing the minimal risk of increased bleeding"
    
    pancreatitis_plan <- "- Abdominal ultrasound now to look for obstructive cause
    - Labs - amylase, lipase, ionized calcium, fasting lipid profile, CRP, tTG-IgA, total IgA, total IgG, IgG4, total bilirubin, direct bilirubin, INR, albumin, AST, ALT, GGT
    - Other tests - sweat chloride"
    
    upper_gi_symptoms_plan <- "- We discussed the differential at this point
    - The next step will be investigation: labs (CBC w diff, tTG-IgA, total IgA, CRP, ESR, albumin), upper GI contrast study (esp to look for stricture or anatomic abnormality)
    - It is likely that the next step after this will be an upper GI endoscopy with biopsies
    - Upper GI series
    - [Trial PPI]"
    
    plan_for_endoscopy <- "We discussed the benefits of endoscopy in this situation, we had a brief discussion about the risks/alternatives also, we also discussed the cleanout/NPO preparation and how the process/procedure occur on the day of the scope"

  # Endoscopy Snippets ----
  
    endoscopy_preparation <- "The nature of the procedure, the risks and benefits and alternatives were explained and informed consent was obtained
    The patient was brought into the procedure room and anesthetized
    A time-out was completed verifying correct patient, procedure, allergies, and special equipment needed if applicable
    The patient was anesthetized as per the anesthesiology record"
    
    upper_endoscopy_findings <- "Duodenum appearance - ***
    Stomach (including retroflexion view) appearance - ***
    Esophagus appearance - ***"
    
    foreign_body_findings <- "Duodenum appearance - ***
    Stomach (including retroflexion view) appearance - ***
    Esophagus appearance - ***
    A [foreign body] was seen in the *** and was retrieved on the *** attempt by *** [tool] and successfully extracted through the mouth
    A repeat look down at the upper tract after removal confirmed that the mucosa was intact and there was no active bleeding"
    
    colonoscopy_findings <- "Perianal and digital rectal exam: ***
    Maximal extent of exam: *** [terminal ileum]
    Terminal ileum appearance: ***
    Colon appearance: ***
    
    Bowel preparation was *** [adequate, suboptimal]"
    
    scope_findings_general <- "Biopsies were taken from each segment
    Deflation was performed and the endoscope was removed
    Complications: none
    Interventions: none"
    
    endoscopy_postprocedure <- "The patient was awoken from anesthesia and brought to the recovery room
    After the procedure the findings were reviewed with the caregivers
    I will follow-up in clinic in 2-4 weeks
    Medication prescribed: none
    Estimated blood Loss: minimal"
  
  
  # Phone Call Snippets ----
  
    body_foreign_body_ingestion <- "Previously healthy - ***
    Swallowed a *** at *** h on ***
    Symptoms - ***yes/no, including ***
    Abdomen - soft and non-tender
    
    Imaging:
    X-ray shows ***"
    
    body_not_foreign_body <- "Patient Background:
    ***
    
    Concern:
    ***
    
    Opinion:
    *** [beware this is based on second hand information transmitted via telephone]"
    
    foreign_body_general <- "[Generally: emergent (<2 hours from presentation, regardless of NPO status), urgent (<24 hours from presentation, following usual NPO guidelines), and elective (>24 hours from presentation, following usual NPO guidelines)]
    [Foreign bodies distal to the stomach are very unlikely to be amenable to endoscopic retrieval, please consult general surgery, as this child may need admission for monitoring]
    [Ask caregiver to monitor stool for object, if seen does not need to seek further medical care for this issue
    If monitoring as outpatient, history suggestive of constipation, suggest trial of PEG 3350 - 0.4 to 1 g/kg (max 17 g) PO daily with plenty of fluid
    Attend to nearest emergency department if any fever, vomiting, severe worsening abdominal pain, bloody stool, or any other major concerning issues]"

  # Billing column names ----
  
    billing_columns <- c("cr",
                         "service_date",
                         "admit_date",
                         "diagnosis_code",
                         "fees",
                         "units",
                         "location",
                         "referring_provider",
                         "my_math")
  
  
  
# Functions for use within the app ----
    
# Save note to docx file with patient name/MRN/visit type as filename when the save button is pressed
    # note: this script will also write an intermediate .txt file with the same information in case office is not available
    # this also allows the text to be reloaded in R line by line which is required for the officer package to place the text
    # into a docx file (officer functions are not vectorized)
  
  savedocxData <- function(data, patient_name, mrn, visit_type) {
    
    txt_filename <- paste0(getwd(), "/", patient_name, "_", mrn, "_", visit_type, ".txt")
    lapply(data, write, txt_filename, append = TRUE, ncolumns = 1000)
    
    docx_filename <- paste0(getwd(), "/", patient_name, "_", mrn, "_", visit_type, ".docx")
    
    text_as_vector <- readLines(txt_filename)
    output_middle <- paste0("body_add_par('", text_as_vector, "') %>%")
    output_final <- c("read_docx() %>%", output_middle, " print(target = docx_filename)")
    
    docx1 <- eval(parse(text = output_final))
    
  }
    
  
  
# Actual app ----
  
shinyApp(

# UI Function ####

ui <- fluidPage(

  # Sidebar layout with a input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(width = 4,
      
      # Sidebar Inputs: ----
        # demographic and visit information that will be loaded into note and billing spreadsheet without having to retype info
      titlePanel("Patient Data:"),
      numericInput("mrn", "Record Number:", value = 1234567, min = 0, max = 999999999),
      textInput("patient_name", "Patient name (First Last):", value = "DM"),
      dateInput("dob", "Date of Birth (YYYY-MM-DD):", value = "2020-01-01"),
      selectInput("sex", "Sex:", choices = c("male", "female", "nonbinary person")),
      textInput("referring_physician", "Referring Physician:", value = ""),
      dateInput("encounter_date", "Encounter Date (YYYY-MM-DD):", value = today()),
      selectInput("visit_type", "Visit Type:", choices = visit_types_list),
      selectInput("location", "Location:", choices = c("clinic", "PRAC", "COPC", "ER", "inpatient")),
      
      # Admission date, only show this panel if "inpatient" location type is selected, required for billing
      conditionalPanel(
        condition = "input.location == 'inpatient'",
        dateInput("admission_date", "Admission Date (YYYY-MM-DD):", value = today())),
      
      selectInput("chief_complaint", "Chief Complaint:", choices = chief_complaints_list),
      
      # Endoscopy type (upper/colon/combo/etc), only show this panel if endoscopy visit type is selected
      conditionalPanel(
        condition = "input.visit_type == 'endoscopy'",
        selectInput("scope_type", "Endoscopy Type:", choices = endoscopy_types_list)),
      
      # Phone call foreign body information, only show these 3 panels if phone call and foreign body are selected
      conditionalPanel(
        condition = "input.visit_type == 'phone call' & input.chief_complaint == 'foreign body ingestion'",
        selectInput("foreign_body_type", "Foreign Body Type:", choices = foreign_body_types_list)),
      conditionalPanel(
        condition = "input.visit_type == 'phone call' & input.chief_complaint == 'foreign body ingestion'",
        selectInput("foreign_body_symptoms", "Foreign Body Symptoms:", choices = c("NA", "yes", "no"))),
      conditionalPanel(
        condition = "input.visit_type == 'phone call' & input.chief_complaint == 'foreign body ingestion'",
        selectInput("foreign_body_location", "Foreign Body Location:", choices = c("NA", "esophagus", "stomach")))
      ),
    
  # Tab 1: Main panel for entering/editing text that will go into note ----
  # the majority of the typing should be done by loading pre-prepared text snippets into the textboxes
  
  mainPanel(width = 8,
    br(),
    tabsetPanel(type = "tabs",
    tabPanel("Composition",
    br(),
    
    # Section Editor Text Boxes
    
    # Accompanied by selector, only show this panel if new or follow up visit type is selected
    conditionalPanel(
      condition = "input.visit_type == 'new' | input.visit_type == 'follow up'",
      selectInput("accompanied_by", "Accompanied by", choices = c("parent",
                                                                "mother",
                                                                "father",
                                                                "non-parent guardian"))
      ),
    
    # Non standard "accompanied by" section where free text (such as "grandparent") can be entered, only shown if "non-parent guardian"
    conditionalPanel(
      condition = "input.accompanied_by == 'non-parent guardian'",
      textInput("guardian", "Guardian", value = "grandparent")
      ),
  
    # Free text to enter a diagnosis if it is a follow up patient
    conditionalPanel(
      condition = "input.visit_type == 'follow up'",
      textInput("diagnosis_section", "Diagnosis", value = "***")
    ),
    
    # Free text to enter a problem list if it is a follow up patient
    conditionalPanel(
      condition = "input.visit_type == 'follow up'",
      textAreaInput("problem_list_section", "Problem List", value = "***", rows = 4, resize = "both")
    ),
    
    # Free text to enter a disease history if it is a follow up patient
    conditionalPanel(
      condition = "input.visit_type == 'follow up'",
      textAreaInput("disease_history_section", "Disease History", value = "***", rows = 4, resize = "both")
    ),
    
    # HPI section for new/follow up visits (with conditional pre-written colitis scoring subsection, if relevant to chief complaint)
    conditionalPanel(
      condition = "input.visit_type == 'new' | input.visit_type == 'follow up'",

            textAreaInput("hpi_section", "History of Presenting Illness",
                        "[brief narrative]", rows = 6, width = "100%", resize = "both"),
        
            conditionalPanel(
              condition = ("input.chief_complaint == 'abdominal pain' |
                           input.chief_complaint == 'bloody diarrhea' |
                           input.chief_complaint == 'IBD exacerbation'"),
              tags$b("Pediatric Ulcerative Colitis Activity Index (PUCAI):"),
              selectInput("pucai_pain", tags$span(style = "font-weight: 400", "Abdominal Pain"), choices = c("No pain (0)",
                                                                      "Pain can be ignored (5)",
                                                                      "Pain cannot be ignored (10)")),
              selectInput("pucai_blood", tags$span(style = "font-weight: 400", "Rectal Bleeding"), choices = c("None (0)",
                                                                        "Small amount only, in <50% of stools (10)",
                                                                        "Small amount with most stools (20)",
                                                                        "Large amount (>50% of stool content) (30)")),
              selectInput("pucai_consistency", tags$span(style = "font-weight: 400", "Consistency of Most Stools"), choices = c("Formed (0)",
                                                                                         "Partially formed (5)",
                                                                                         "Completely unformed (10)")),
              selectInput("pucai_number", tags$span(style = "font-weight: 400", "Number of Stools per 24h"), choices = c("0-2 (0)",
                                                                                  "3-5 (5)",
                                                                                  "6-8 (10)",
                                                                                  ">8 (15)")),
              selectInput("pucai_nocturnal", tags$span(style = "font-weight: 400", "Nocturnal Stools (causing waking)"), choices = c("No (0)",
                                                                                              "Yes (10)")),
              selectInput("pucai_activity", tags$span(style = "font-weight: 400", "Activity Level"), choices = c("No limitation (0)",
                                                                          "Occasional limitation (5)",
                                                                          "Severe restriction (10)")),
              textOutput("pucai_total_score"),
              br()
              )
      ),
    
    # Review of systems section if relevant visit type
    conditionalPanel(
      condition = "input.visit_type == 'new' | input.visit_type == 'follow up'",
              textAreaInput("ros_section", "Review of Systems", ros_text, width = "100%", rows = 9)
      ),
    
    # Past Medical History of new patient
    conditionalPanel(
      condition = "input.visit_type == 'new'",
      textAreaInput("pmhx_section", "Past Medical History", young_pmhx, width = "100%", rows = 4)
      ),
    
    # Medications section free text if relevant visit type
    conditionalPanel(
      condition = "input.visit_type == 'new' | input.visit_type == 'follow up'",
      textInput("meds_section", "Medications", "None***", width = "100%")
      ),
    
    # Full patient background if new patient (allergies, immunizations, developmental history, social history, family history)
    conditionalPanel(
      condition = "input.visit_type == 'new'",
        textInput("allergies_section", "Allergies", "None***", width = "100%"),
        textInput("immunizations_section", "Immunizations", "Up to date, by report***", width = "100%"),
        textInput("devhx_section", "Developmental History", "*** concerns, *** regression", width = "100%"),
        textAreaInput("socialhx_section", "Social History", social_hx, width = "100%", rows = 2),
        textAreaInput("familyhx_section", "Family History", gi_famhx, width = "100%", rows = 6)
      ),
    
    # Impression section if relevant visit type
    conditionalPanel(
      condition = "input.visit_type == 'new' | input.visit_type == 'follow up'",
        textAreaInput("pex_section", "Physical Examination", general_pex, width = "100%", rows = 6),
        textAreaInput("inv_section", "Investigations", inv, width = "100%", rows = 4),
        textAreaInput("impression_section",
                      "Impression [Note: The ID line, ie '7 yo M presenting w X.', is added automatically below]",
                      impression_generic,
                      width = "100%",
                      rows = 7),
        textAreaInput("assessment_section", "Assessment", assessment_text, width = "100%", rows = 7)
    ),
    
    # If phone call visit type, displays relevant sections: call timing, calling physician and blank note
    conditionalPanel(
      condition = ("input.visit_type == 'phone call'"),
      textInput("discussion_time_section", "Discussion Time (must be >=10 min to bill):", paste0(hour(now()), minute(now()), "h to ***"), "h to *** h [must be >=10 min]", width = "100%"),
      textInput("call_from_section", "Call From:", "***", width = "100%"),
      textAreaInput("phone_call_section", "Phone Call Note", "***", width = "100%", rows = 10)
    ),
    
    # Plan section for all visit types (except endoscopy)
    conditionalPanel(
      condition = ("input.visit_type != 'endoscopy'"),
        textAreaInput("plan_section", "Plan", plan_text, width = "100%", rows = 10)
      ),
    
    # Relevant sections if endoscopy visit type    
    conditionalPanel(
      condition = ("input.visit_type == 'endoscopy'"),
      textAreaInput("scope_findings_section", "Endoscopy Findings", "***", width = "100%", rows = 8)
    )),
    
    tabPanel("Note Preview",
             
  # Tab 2: Output (text note) Preview ----
  br(),
  h3("- Output Preview - "),
  br(),
  tagAppendAttributes(textOutput("full_note"), style = "white-space:pre-wrap;"),
  br(),
  br(),
  actionButton("docx", "Save Note (as word document)", icon("download")),
  br(),
  br(),
  actionButton("save", "Save Encounter to Billing Database", icon("database")),
  br(),
  br()
  )))
  )
),

# Server Function ####

server <- function(input, output, session) {
  
  # For each section of the note, there is either a default text loaded into the textbox
    # or
  # a context specific pre-written text snippets that will change depending on the demographic info in the sidebar
    # the demographic info is all reactive and will change the textbox structure and note output preview dynamically if updated
  
  # Diagnosis Section ----
    
    output$diagnosis_saved_text <- renderText({input$diagnosis_section})
    
  # Problem List Section ----
    
    output$problem_list_saved_text <- renderText({input$problem_list_section})
    
  # Disease History Section ----
    
    output$disease_history_saved_text <- renderText({input$disease_history_section})
  
  # History of Presenting Illness Section ----
    
    observe({
      
      updateTextAreaInput(session, "hpi_section",
                          value = 
                            if (input$chief_complaint == "neonatal cholestasis") {
                                paste(hpi_neonatal_cholestasis, sep = "\n")
                              }  else if (input$chief_complaint == "IBD exacerbation") {
                                paste(ibd_background, sep = "\n")
                                } else {
                                  paste(hpi_text, sep = "\n")
                                  }
                          )
      
    })
  
    output$hpi_saved_text <- renderText({input$hpi_section})

    
  # PUCAI Section ----
    
    output$pucai_total_score <- renderText({
      pain_score <- if (input$pucai_pain == "No pain (0)") {
        0
      } else if (input$pucai_pain == "Pain can be ignored (5)") {
        5
      } else if (input$pucai_pain == "Pain cannot be ignored (10)") {
        10
      }
      
      blood_score <- if (input$pucai_blood == "None (0)") {
        0
      } else if (input$pucai_blood == "Small amount only, in <50% of stools (10)") {
        10
      } else if (input$pucai_blood == "Small amount with most stools (20)") {
        20
      } else if (input$pucai_blood == "Large amount (>50% of stool content) (30)") {
        30
      }
      
      consistency_score <- if (input$pucai_consistency == "Formed (0)") {
        0
      } else if (input$pucai_consistency == "Partially formed (5)") {
        5
      } else if (input$pucai_consistency == "Completely unformed (10)") {
        10
      }
      
      number_score <- if (input$pucai_number == "0-2 (0)") {
        0
      } else if (input$pucai_number == "3-5 (5)") {
        5
      } else if (input$pucai_number == "6-8 (10)") {
        10
      } else if (input$pucai_number == ">8 (15)") {
        15
      }
      
      nocturnal_score <- if (input$pucai_nocturnal == "No (0)") {
        0
      } else if (input$pucai_nocturnal == "Yes (10)") {
        10
      }
      
      activity_score <- if (input$pucai_activity == "No limitation (0)") {
        0
      } else if (input$pucai_activity == "Occasional limitation (5)") {
        5
      } else if (input$pucai_activity == "Severe restriction (10)") {
        10
      }
      
      glue("PUCAI = ",
           (pain_score +
              blood_score +
              consistency_score +
                number_score +
                  nocturnal_score +
                    activity_score),
           "/85 (< 10 denotes clinical remission, 10-34 is clinically mild disease, 35-64 is clinically moderate disease, and 65-85 is clinically severe disease)")
    })
    
    
  # Review of Systems Section ----
    
    observe({
      cc <- input$chief_complaint
      
      updateTextAreaInput(session, "ros_section",
                          value = 
                            if (cc == "abdominal pain") {
                                paste(general_ros, upper_gi_ros, diet_recall_ros, stooling_ros, id_ros, gu_ros, neuro_ros, sep = "\n")
                              } else if (cc == "constipation") {
                                paste(general_ros, upper_gi_ros, diet_recall_ros, stooling_ros, gu_ros, neuro_ros, sep = "\n")
                              } else if (cc == "pancreatitis") {
                                paste(general_ros, upper_gi_ros, diet_recall_ros, stooling_ros, gu_ros, id_ros, neuro_ros, liver_ros, sep = "\n")
                              } else if (cc == "abnormal liver tests") {
                                paste(general_ros, stooling_ros, liver_ros, id_ros, sep = "\n")
                              } else if (cc == "upper GI symptoms") {
                                paste(general_ros, upper_gi_ros, eoe_ros, diet_recall_ros, stooling_ros, sep = "\n")
                              } else if (cc == "bloody diarrhea") {
                                paste(general_ros, upper_gi_ros, eim_ros, id_ros, sep = "\n")
                              } else if (cc == "non-bloody diarrhea") {
                                paste(general_ros, upper_gi_ros, eim_ros, id_ros, sep = "\n")
                              } else if (cc == "neonatal cholestasis") {
                                paste(general_ros, stooling_ros, sep = "\n")
                              } else if (cc == "possible celiac disease") {
                                paste(general_ros, upper_gi_ros, eim_ros, diet_recall_ros, stooling_ros, celiac_ros, sep = "\n")
                              } else if (cc == "choledocholithiasis") {
                                paste(general_ros, upper_gi_ros, diet_recall_ros, stooling_ros, liver_ros, sep = "\n")
                              } else if (cc == "generic") {
                                paste(general_ros, upper_gi_ros, diet_recall_ros, stooling_ros, gu_ros, neuro_ros, liver_ros, id_ros, sep = "\n")
                              } else if (cc == "infant feeding difficulties") {
                                paste(general_ros, infant_feeding_ros, stooling_ros, sep = "\n")
                              } else if (cc == "GI bleed") {
                                paste(general_ros, bleed_ros, upper_gi_ros, stooling_ros, liver_ros, id_ros, sep = "\n")
                              }  else if (cc == "IBD exacerbation") {
                                paste(ibd_ros, sep = "\n")
                              } else {
                                paste(general_ros, upper_gi_ros, diet_recall_ros, stooling_ros, gu_ros, neuro_ros, liver_ros, id_ros, sep = "\n")
                              }
                          )
      })
    
    output$ros_saved_text <- renderText({input$ros_section})
    
  # Past medical history (and meds/allergies/imm/dev Hx) Section ----
    
    observe({

      age_raw <- 
        if (is.na(input$dob)) {
          as.period(interval(start = "2010-01-01", end = input$encounter_date))
        } else {
          as.period(interval(start = input$dob, end = input$encounter_date))
        }
      
      updateTextAreaInput(session, "pmhx_section",
                          value = 
                            if (age_raw$year < 2) {
                              paste(young_pmhx)
                            } else {
                              paste(older_pmhx)
                            }
                          )
      })
    
    output$pmhx_saved_text <- renderText({input$pmhx_section})
    
    output$meds_saved_text <- renderText({input$meds_section})
    
    output$allergies_saved_text <- renderText({req(input$allergies_section)})
    
    output$immunizations_saved_text <- renderText({input$immunizations_section})
    
    output$devhx_saved_text <- renderText({input$devhx_section})
    
  # Social Hx Section ----
    observe({
      
      age_raw <- 
        if (is.na(input$dob)) {
          as.period(interval(start = "2010-01-01", end = input$encounter_date))
        } else {
          as.period(interval(start = input$dob, end = input$encounter_date))
        }
      
      updateTextAreaInput(session, "socialhx_section",
                          value = 
                            if(age_raw$year < 12){
                              paste(social_hx)
                            } else {
                              paste(heads_hx)
                            }
                          )

    })
    
    output$socialhx_saved_text <- renderText({input$socialhx_section})    
    
  # Family History Section ----
    
    observe({
      
      cc <- input$chief_complaint
      
      updateTextAreaInput(session, "familyhx_section",
                          value = 
                            if (cc == "choledocholithiasis" | cc == "abnormal liver tests" | cc == "neonatal cholestasis") {
                              paste(liver_famhx)
                            } else if (cc == "pancreatitis") {
                              paste(pancreatitis_famhx, liver_famhx, sep = "\n")
                            } else if (cc == "upper GI symptoms") {
                              paste(gi_famhx, eoe_famhx, sep = "\n")
                            } else {
                              paste(gi_famhx)
                            }
      )
    })
    
    output$familyhx_saved_text <- renderText({input$familyhx_section})
    
  # Physical Exam Section ----
    observe({
      
      cc <- input$chief_complaint
      
      updateTextAreaInput(session, "pex_section",
                          value = 
                            if (cc == "abdominal pain") {
                              paste(general_pex, abdo_pex, sep = "\n")
                            } else if (cc == "constipation") {
                              paste(general_pex, abdo_pex, perianal_pex, neuro_msk_pex, sep = "\n")
                            } else if (cc == "pancreatitis") {
                              paste(general_pex, abdo_pex, sep = "\n")
                            } else if (cc == "abnormal liver tests") {
                              paste(general_pex, liver_pex, sep = "\n")
                            } else if (cc == "upper GI symptoms") {
                              paste(general_pex, heent_pex, abdo_pex, sep = "\n")
                            } else if (cc == "bloody diarrhea") {
                              paste(general_pex, heent_pex, abdo_pex, perianal_pex, sep = "\n")
                            } else if (cc == "neonatal cholestasis") {
                              paste(general_pex, liver_pex, sep = "\n")
                            } else if (cc == "possible celiac disease") {
                              paste(general_pex, abdo_pex, sep = "\n")
                            } else if (cc == "choledocholithiasis") {
                              paste(general_pex, liver_pex, sep = "\n")
                            } else if (cc == "generic") {
                              paste(general_pex, heent_pex, abdo_pex, liver_pex, perianal_pex, neuro_msk_pex, sep = "\n")
                            }
      )
    })
    
    output$pex_saved_text <- renderText({input$pex_section})
    
  # Investigations Section ----
    
    output$inv_saved_text <- renderText({input$inv_section})
    
  # Impression Section ----
    
    output$impression_saved_text <- renderText({
      
      cc <- input$chief_complaint
      
      age_raw <- 
        if (is.na(input$dob)) {
          as.period(interval(start = "2010-01-01", end = input$encounter_date))
        } else {
          as.period(interval(start = input$dob, end = input$encounter_date))
        }
      
      age <- if(age_raw$year < 2){
        if(age_raw$month <1){
          paste(age_raw$day, "day")
        } else {
          paste(age_raw$month + (12*age_raw$year), "month")}
      } else {
        paste(age_raw$year, "year")}
      
      sex <- input$sex
      
      heshe <- if (sex == "male") {
        "he"
      } else if (sex == "female") {
        "she"
      } else {
        "they"
      }
      
      himher <- if (sex == "male") {
        "him"
      } else if (sex == "female") {
        "her"
      } else {
        "them"
      }
      
      hisher <- if (sex == "male") {
        "his"
      } else if (sex == "female") {
        "her"
      } else {
        "their"
      }
      
      return(paste0(input$patient_name,
                    " is a ",
                    age,
                    " old ",
                    input$sex,
                    " who presents with ",
                    input$chief_complaint,
                    "."))

    })
    
    observe({
      
      cc <- input$chief_complaint
      
      updateTextAreaInput(session, "impression_section",
                          value = 
                            if (cc == "neonatal cholestasis") {
                              paste(impression_generic, impression_neonatal_cholestasis)
                            } else if (cc == "GI bleed") {
                              paste(impression_generic, impression_gi_bleed)
                            } else if (cc == "choledocholithiasis") {
                              paste(impression_generic, impression_choledocholithiasis)
                            } else if (cc == "abnormal liver tests") {
                              paste(impression_generic, impression_abnormal_liver_tests)
                            } else if (cc == "upper GI symptoms") {
                              paste(impression_generic, impression_upper_gi_symptoms)
                            } else if (cc == "bloody diarrhea") {
                              paste(impression_generic, impression_bloody_diarrhea)
                            } else {
                              paste(impression_generic, impression_text)
                            }
      )
    })
    
    output$impression_saved_text2 <- renderText({input$impression_section})
    
  # Assessment Section ----
    observe({
      
      cc <- input$chief_complaint
      
      updateTextAreaInput(session, "assessment_section",
                          value = 
                            if (cc == "abdominal pain") {
                              paste(assessment_abdominal_pain)
                            } else if (cc == "neonatal cholestasis") {
                              paste(assessment_neonatal_cholestasis)
                            } else if (cc == "non-bloody diarrhea") {
                              paste(assessment_non_blood_diarrhea)
                            } else if (cc == "pancreatitis") {
                              paste(assessment_pancreatitis)
                            } else if (cc == "abnormal liver tests") {
                              paste(assessment_abnormal_liver_tests)
                            } else if (cc == "possible celiac disease") {
                              paste(assessment_possible_celiac_disease)
                            } else if (cc == "upper GI symptoms") {
                              paste(assessment_upper_gi_symptoms)
                            } else if (cc == "GI bleed") {
                              paste(assessment_gi_bleed)
                            } else if (cc == "bloody diarrhea") {
                              paste(assessment_bloody_diarrhea)
                            } else {
                              paste("")
                            }
                        )
    })
    
    output$assessment_saved_text <- renderText({input$assessment_section})
    
  # Phone Call Section ----
    
    output$discussion_time_saved_text <- renderText({input$discussion_time_section})
    
    output$call_from_saved_text <- renderText({input$call_from_section})
    
    
    observe({
      
      cc <- input$chief_complaint
      
      updateTextAreaInput(session, "phone_call_section",
                          value = 
                            if (input$chief_complaint == "foreign body ingestion") {
                              body_foreign_body_ingestion
                            } else {
                              body_not_foreign_body
                            })
      })
       
    output$phone_call_saved_text <- renderText({input$phone_call_section})
    
  # Plan Section ----
    # Note that this section includes a deep tree of logical if/else-if statements for foreign bodies
    
    # The logic and pre-written text statements are pulled directly from the current guidelines for pediatric foreign body management,
      # this allows the user to select the relevant information and make a plan based on the guidelines,
      # decreasing the chances of misreading a table or flowchart in the guidelines
    
    # There is also a default generic plan built in to help when the patient's presentation doesn't apply to any of the chief complaints
    # (the generic plan will be used if the chief complaint is not covered in any of the if/else-if logic statements)
    
    observe({
      
      cc <- input$chief_complaint
      
      updateTextAreaInput(session, "plan_section",
                          value = 
                            if (cc == "abdominal pain") {
                              paste(abdominal_pain_plan)
                            } else if (cc == "constipation") {
                              paste(constipation_plan)
                            } else if (cc == "neonatal cholestasis") {
                              paste(neonatal_cholestasis_plan)
                            } else if (cc == "possible celiac disease") {
                              paste(possible_celiac_disease_plan)
                            } else if (cc == "choledocholithiasis") {
                              paste(choledocholithiasis_plan)
                            } else if (cc == "infant feeding difficulties") {
                              paste(infant_feeding_difficulties_plan)
                            } else if (cc == "failure to thrive") {
                              paste(failure_to_thrive_plan)
                            } else if (cc == "GI bleed") {
                              paste(gi_bleed_plan)
                            } else if (cc == "abnormal liver tests") {
                              paste(abnormal_liver_tests_plan)
                            } else if (cc == "bloody diarrhea") {
                              paste(bloody_diarrhea_plan)
                            } else if (cc == "IBD exacerbation") {
                              paste(ibd_exacerbation_plan)
                            } else if (cc == "pancreatitis") {
                              paste(pancreatitis_plan)
                            } else if (cc == "upper GI symptoms") {
                              paste(upper_gi_symptoms_plan)
                            } else if (cc == "foreign body ingestion") {
                              if (input$foreign_body_type == "button battery") {
                                if (input$foreign_body_location == "esophagus") {
                                  paste("- Remove emergently/immediately (be sure to have surgery/cardiovasc surgery team available if unstable or actively bleeding)", foreign_body_general)
                                } else if (input$foreign_body_location == "stomach") {
                                  if (input$foreign_body_symptoms == "yes") {
                                    paste("- Remove emergently/immediately")
                                  } else if (input$foreign_body_symptoms == "no") {
                                    paste("- If in stomach and if age <5 yo AND BB >20 mm, remove urgently, otherwise elective removal if not moving on serial x-rays",
                                          "- Repeat x-ray in 48 hours for BB ≥20 mm, repeat at 10–14 days for BB <20 mm if failure to pass in stool", foreign_body_general,
                                          sep = "\n")
                                  }
                                }
                              } else if (input$foreign_body_type == "magnets") {
                                if (input$foreign_body_location == "esophagus") {
                                  if (input$foreign_body_symptoms == "yes") {
                                    paste("- If not handling secretions, remove emergently/immediately",
                                          "- If handling secretions, remove urgently", foreign_body_general,
                                          sep = "\n")
                                  } else if (input$foreign_body_symptoms == "no") {
                                    paste("- Remove urgently", foreign_body_general)
                                  }
                                } else if (input$foreign_body_location == "stomach") {
                                  if (input$foreign_body_symptoms == "yes") {
                                    paste("- Remove emergently/immediately", foreign_body_general)
                                  } else if (input$foreign_body_symptoms == "no") {
                                    paste("- Remove urgently", foreign_body_general)
                                  }
                                }
                              } else if (input$foreign_body_type == "sharp") {
                                if (input$foreign_body_location == "esophagus") {
                                  if (input$foreign_body_symptoms == "yes") {
                                    paste("- If not handling secretions, remove emergently/immediately",
                                          "- If handling secretions, remove urgently", foreign_body_general,
                                          sep = "\n")
                                  } else if (input$foreign_body_symptoms == "no") {
                                    paste("- Remove urgently")
                                  }
                                } else if (input$foreign_body_location == "stomach") {
                                  if (input$foreign_body_symptoms == "yes") {
                                    paste("- If not handling secretions, remove emergently/immediately",
                                          "- If handling secretions, remove urgently", foreign_body_general,
                                          sep = "\n")
                                  } else if (input$foreign_body_symptoms == "no") {
                                    paste("- Remove urgently")
                                  }
                                }
                              } else if (input$foreign_body_type == "food impaction") {
                                if (input$foreign_body_symptoms == "yes") {
                                  paste("- If not handling secretions, remove emergently/immediately",
                                        "- If handling secretions, remove urgently", foreign_body_general,
                                        sep = "\n")
                                } else if (input$foreign_body_symptoms == "no") {
                                  paste("- Remove urgently", foreign_body_general)
                                }
                              } else if (input$foreign_body_type == "coin") {
                                if (input$foreign_body_location == "esophagus") {
                                  if (input$foreign_body_symptoms == "yes") {
                                    paste("- If not handling secretions, remove emergently/immediately",
                                          "- If handling secretions, remove urgently", foreign_body_general,
                                          sep = "\n")
                                  } else if (input$foreign_body_symptoms == "no") {
                                    paste("- Remove urgently", foreign_body_general)
                                  }
                                } else if (input$foreign_body_location == "stomach") {
                                  if (input$foreign_body_symptoms == "yes") {
                                    paste("- Remove urgently", foreign_body_general)
                                  } else if (input$foreign_body_symptoms == "no") {
                                    paste("- Elective removal if not moving on repeat abdo x-ray after 2-4 weeks", foreign_body_general)
                                  }
                                }
                              } else if (input$foreign_body_type == "long object") {
                                paste("- Remove urgently")
                              } else if (input$foreign_body_type == "absorptive object") {
                                if (input$foreign_body_location == "esophagus") {
                                  paste("- If not handling secretions, remove emergently/immediately",
                                        "- If handling secretions, remove urgently", foreign_body_general,
                                        sep = "\n")
                                } else if (input$foreign_body_location == "stomach") {
                                  paste("- Remove urgently", foreign_body_general)
                                }
                              }
                            } else {
                              paste("We discussed:
                                      - the diagnosis or most likely diagnoses +/- prognosis
                                    	- next steps/investigations (which I have arranged/will arrange)
                                    	- treatment
                                    	- diet discussion for all patients")
                            }
  
      )
    })
    
    output$plan_saved_text <- renderText({input$plan_section})
    
  # Scope Findings Section ----
    observe({

      updateTextAreaInput(session, "scope_findings_section",
                          value = 
                            if (input$scope_type == "Upper Endoscopy") {
                              paste(upper_endoscopy_findings, sep = "\n")
                            } else if (input$scope_type == "Upper Endoscopy and Colonoscopy") {
                              paste(upper_endoscopy_findings, colonoscopy_findings, sep = "\n")
                            } else if (input$scope_type == "Colonoscopy") {
                              paste(colonoscopy_findings, sep = "\n")
                            } else if (input$scope_type == "Upper Endoscopy Foreign Body Removal") {
                              paste(foreign_body_findings, sep = "\n")
                            }
      )
    })
    
    output$scope_findings_saved_text <- renderText({input$scope_findings_section})
    
    
  # Data saving/collating section ----
    
    # Downloadable dataset ----
    
    # Whenever a field is filled, this reactive function will aggregate all form data into consult/follow_up/etc text object
      # Then that object can be previewed in the second tab of the UI and saved for uploading to the EMR
    # This is a large block of text, but can be summarized as a function that takes all the input text and creates a combined
      # text object that includes only the relevant sections to that patient encounter
      # for example, the endoscopy findings sections are not included in a phone call encounter, etc
    
    formData <- reactive({
      
      recreate_id_text <- function(...){
        
        guardian_text_raw <- input$accompanied_by
        guardian <- input$guardian
        
        guardian_title <- if(guardian_text_raw == "non-parent guardian"){
          paste(guardian)
        } else {
          paste(guardian_text_raw)
        }
        
        age_raw <- 
          if (is.na(input$dob)) {
            as.period(interval(start = "2010-01-01", end = input$encounter_date))
          } else {
            as.period(interval(start = input$dob, end = input$encounter_date))
          }
        
        age <- if(age_raw$year < 2){
          if(age_raw$month <1){
            paste(age_raw$day, "day")
          } else {
            paste(age_raw$month + (12*age_raw$year), "month")}
        } else {
          paste(age_raw$year, "year")}
        
        # Gender Identifier Objects
        
        sex <- input$sex
        
        heshe <- if (sex == "male") {
          "he"
        } else if (sex == "female") {
          "she"
        } else {
          "they"
        }
        
        himher <- if (sex == "male") {
          "him"
        } else if (sex == "female") {
          "her"
        } else {
          "them"
        }
        
        hisher <- if (sex == "male") {
          "his"
        } else if (sex == "female") {
          "her"
        } else {
          "their"
        }
        
        # Location Information
        
        location <- input$location
        
        location_name <- if ((location == "clinic") | (location == "PRAC")) {
          "pediatric outpatient clinic"
        } else if (location == "COPC") {
          "pediatric urgent care clinic"
        } else if (location == "ER") {
          "emergency department"
        } else if (location == "inpatient") {
          "pediatrics ward"
        }
        
        
        id_text_object <- paste0(input$patient_name,
                                 " is a ",
                                 age,
                                 " old ",
                                 input$sex,
                                 " seen by the pediatric gastroenterology service in the ",
                                 location_name,
                                 " on ",
                                 paste(wday(input$encounter_date, label = TRUE, abbr = FALSE)),
                                 " ",
                                 paste(month(input$encounter_date, label = TRUE, abbr = FALSE)),
                                 " ", paste0(mday(input$encounter_date)),
                                 ", ",
                                 paste(year(input$encounter_date)),
                                 ". ",
                                 str_to_title(heshe),
                                 " was accompanied by ",
                                 hisher,
                                 " ",
                                 guardian_title,
                                 ".")
        
        return(id_text_object)
    }
      
    recreate_pucai_text <- function(...){
      pain_score <- if (input$pucai_pain == "No pain (0)") {
        0
      } else if (input$pucai_pain == "Pain can be ignored (5)") {
        5
      } else if (input$pucai_pain == "Pain cannot be ignored (10)") {
        10
      }
      
      pain_text <- input$pucai_pain

      blood_score <- if (input$pucai_blood == "None (0)") {
        0
      } else if (input$pucai_blood == "Small amount only, in <50% of stools (10)") {
        10
      } else if (input$pucai_blood == "Small amount with most stools (20)") {
        20
      } else if (input$pucai_blood == "Large amount (>50% of stool content) (30)") {
        30
      }
      
      blood_text <- input$pucai_blood

      consistency_score <- if (input$pucai_consistency == "Formed (0)") {
        0
      } else if (input$pucai_consistency == "Partially formed (5)") {
        5
      } else if (input$pucai_consistency == "Completely unformed (10)") {
        10
      }
      
      consistency_text <- input$pucai_consistency

      number_score <- if (input$pucai_number == "0-2 (0)") {
        0
      } else if (input$pucai_number == "3-5 (5)") {
        5
      } else if (input$pucai_number == "6-8 (10)") {
        10
      } else if (input$pucai_number == ">8 (15)") {
        15
      }
      
      number_text <- input$pucai_number

      nocturnal_score <- if (input$pucai_nocturnal == "No (0)") {
        0
      } else if (input$pucai_nocturnal == "Yes (10)") {
        10
      }
      
      nocturnal_text <- input$pucai_nocturnal

      activity_score <- if (input$pucai_activity == "No limitation (0)") {
        0
      } else if (input$pucai_activity == "Occasional limitation (5)") {
        5
      } else if (input$pucai_activity == "Severe restriction (10)") {
        10
      }
      
      activity_text <- input$pucai_activity
      
      total_pucai_score <- pain_score +
        blood_score +
        consistency_score +
        number_score +
        nocturnal_score +
        activity_score

      if (input$chief_complaint == "abdominal pain" | input$chief_complaint == "bloody diarrhea" | input$chief_complaint == "IBD exacerbation"){
      return(glue("\n", "\n", "Pediatric Ulcerative Colitis Activity Index (PUCAI):",
                  "\n",
                  paste("Abdominal Pain:", pain_text),
                  "\n",
                  paste("Rectal Bleeding:", blood_text),
                  "\n",
                  paste("Consistency of Most Stools:", consistency_text),
                  "\n",
                  paste("Number of Stools per 24h:", number_text),
                  "\n",
                  paste("Nocturnal Stools (causing waking):", nocturnal_text),
                  "\n",
                  paste("Activity Level:", activity_text),
                  "\n",
                  "Total PUCAI = ", 
                  (total_pucai_score),
                  "/85 (< 10 denotes clinical remission, 10-34 is clinically mild disease, 35-64 is clinically moderate disease, and 65-85 is clinically severe disease)",
                  "\n",
                  "\n"
      )
      )
      }
    }
      
      recreate_impression_text <- function(...){
        
        cc <- input$chief_complaint
        
        age_raw <- 
          if (is.na(input$dob)) {
            as.period(interval(start = "2010-01-01", end = input$encounter_date))
          } else {
            as.period(interval(start = input$dob, end = input$encounter_date))
          }
        
        age <- if(age_raw$year < 2){
          if(age_raw$month <1){
            paste(age_raw$day, "day")
          } else {
            paste(age_raw$month + (12*age_raw$year), "month")}
        } else {
          paste(age_raw$year, "year")}
        
        sex <- input$sex
        
        heshe <- if (sex == "male") {
          "he"
        } else if (sex == "female") {
          "she"
        } else {
          "they"
        }
        
        himher <- if (sex == "male") {
          "him"
        } else if (sex == "female") {
          "her"
        } else {
          "them"
        }
        
        hisher <- if (sex == "male") {
          "his"
        } else if (sex == "female") {
          "her"
        } else {
          "their"
        }
        
        return(paste0(input$patient_name,
                      " is a ",
                      age,
                      " old ",
                      input$sex,
                      " who presents with ",
                      input$chief_complaint,
                      "."))
        
      }
      
      
      consult <- paste("Pediatric Gastroenterology Consult",
                "",
                "Identification",
                recreate_id_text(),
                "",
                "Reason for Referral",
                "[quotation directly from referral]",
                paste0("- Dr. ", input$referring_physician),
                "",
                "History of Presenting Illness",
                input$hpi_section,
                recreate_pucai_text(),
                "Review of Systems",
                input$ros_section,
                "",
                "Past Medical History",
                input$pmhx_section,
                "",
                "Medications",
                input$meds_section,
                "",
                "Allergies",
                input$allergies_section,
                "",
                "Immunizations",
                input$immunizations_section,
                "",
                "Developmental History",
                input$devhx_section,
                "",
                "Social History",
                input$socialhx_section,
                "",
                "Family History",
                input$familyhx_section,
                "",
                "Physical Examination",
                input$pex_section,
                "",
                "Investigations",
                input$inv_section,
                "",
                "Impression",
                recreate_impression_text(),
                input$impression_section,
                "",
                input$assessment_section,
                "",
                "Plan",
                input$plan_section,
                "- Clinic contact information provided [if ongoing follow up]",
                "",
                "Sincerely,",
                "",
                "[trainee name and designation]",
                "",
                "On behalf of",
                "",
                "Daniel Mulder, Pediatric Gastroenterologist, MD, FRCPC",
                sep = "\n"
      )
      
      follow_up <- paste("Pediatric Gastroenterology Follow Up",
                         "",
                         "Identification",
                         recreate_id_text(),
                         "",
                         "Diagnosis:",
                         input$diagnosis_section,
                         "",
                         "Problem List:",
                         input$problem_list_section,
                         "",
                         "Disease History:",
                         input$disease_history_section,
                         "",
                         "Updates:",
                         input$hpi_section,
                         "",
                         recreate_pucai_text(),
                         "Review of Systems",
                         input$ros_section,
                         "",
                         "Medications",
                         input$meds_section,
                         "",
                         "Physical Examination",
                         input$pex_section,
                         "",
                         "Investigations",
                         input$inv_section,
                         "",
                         "Impression",
                         recreate_impression_text(),
                         input$impression_section,
                         "",
                         input$assessment_section,
                         "",
                         "Plan",
                         input$plan_section,
                         "",
                         "Sincerely,",
                         "",
                         "[trainee name and designation]",
                         "",
                         "On behalf of",
                         "",
                         "Daniel Mulder, Pediatric Gastroenterologist, MD, FRCPC",
                         sep = "\n")
      
      procedure_details <- function(...) {
        
        age_raw <- 
          if (is.na(input$dob)) {
            as.period(interval(start = "2010-01-01", end = input$encounter_date))
          } else {
            as.period(interval(start = input$dob, end = input$encounter_date))
          }

        age <- if(age_raw$year < 2){
          if(age_raw$month <1){
            paste(age_raw$day, "day")
          } else {
            paste(age_raw$month + (12*age_raw$year), "month")}
        } else {
          paste(age_raw$year, "year")}

        return(paste0("Patient: ",
                      input$patient_name,
                      ", ",
                      age,
                      " old ",
                      input$sex,
                      "\n",
                      "Date of Procedure: ",
                      paste(wday(input$encounter_date, label = TRUE, abbr = FALSE)),
                      " ",
                      paste(month(input$encounter_date, label = TRUE, abbr = FALSE)),
                      " ",
                      paste0(mday(input$encounter_date)),
                      ", ",
                      paste(year(input$encounter_date))
                      )
               )
      }

      procedure_done <- function(...) {
        return(paste("Procedure:", input$scope_type))
      }

      procedure_indication <- function(...) {
        return(paste("Indication:", input$chief_complaint))
      }

      scope_findings <- function(...) {
        return(paste(input$scope_findings_section))
      }

      endoscopy_note <- paste("Endoscopy Procedure Note",
        "",
        "Procedure Details:",
        procedure_details(),
        "Proceduralist: Daniel Mulder, Staff Pediatric Gastroenterologist",
        "Location: KGH OR",
        procedure_done(),
        procedure_indication(),
        "",
        "Preparation:",
        endoscopy_preparation,
        "",
        "Procedure:",
        scope_findings(),
        "",
        scope_findings_general,
        "",
        "Post Procedure:",
        endoscopy_postprocedure,
        "",
        "Sincerely,",
        "",
        "Daniel Mulder, Pediatric Gastroenterologist, MD, FRCPC",
        sep = "\n"
      )
       
      phone_date <- function(...) {
        paste("Date: ",
               wday(input$encounter_date, label = TRUE, abbr = FALSE),
               month(input$encounter_date, label = TRUE, abbr = FALSE),
               mday(input$encounter_date),
               year(input$encounter_date)
        )
      }
      
      phone_time <- function(...) {
        paste0("Discussion Time: ", input$discussion_time_section, "h")
      }
      
      phone_age <- function(...) {
        age_raw <- 
          if (is.na(input$dob)) {
            as.period(interval(start = "2010-01-01", end = input$encounter_date))
          } else {
            as.period(interval(start = input$dob, end = input$encounter_date))
          }
        
        age <- if(age_raw$year < 2){
          if(age_raw$month <1){
            paste(age_raw$day, "day")
          } else {
            paste(age_raw$month + (12*age_raw$year), "month")}
        } else {
          paste(age_raw$year, "year")}
        
        paste0("Patient Age:", "\n", age, " old")
      }
      
       phone_call <- paste("Pediatric Gastroenterology Telephone Consultation",
                           "",
                           phone_date(),
                           phone_time(),
                           "",
                           "Call From",
                           input$call_from_section,
                           "",
                           phone_age(),
                           "",
                           input$phone_call_section,
                           "",
                           input$plan_section,
                           "Advise to attend to nearest emergency department if any major changes or other major concerning issues",
                           "The advice was reviewed and all were in agreement",
                           "",
                           "Daniel Mulder, Pediatric Gastroenterologist, MD, FRCPC",
                           sep = "\n")
                           
      if (input$visit_type == "new") {
        return(consult)
      } else if (input$visit_type == "follow up") {
        return(follow_up)
      } else if (input$visit_type == "endoscopy") {
        return(endoscopy_note)
      } else if (input$visit_type == "phone call") {
        return(phone_call)
      }
       
    }) # end of the formData reactive function
    
    # full_note text object to render a preview of the note in the "Output Preview" tab of the UI
    
    output$full_note <- renderText(formData())

    # When the save button is clicked, the function below will save the text as a .docx file
      # (also saves as a txt file in case user does not use office)
      # In order to create the filename it requires the arguments: patient_name, mrn and visit_type
      # the rest of the note is created from the formData() function above
    
    observeEvent(input$docx, {
      savedocxData(formData(), input$patient_name, input$mrn, input$visit_type)
    })
    
  # Billing Section ----
    
    # when the billing button is pressed, the function below will load the billing spreadsheet and save a new row to it
    # if there is no "billing_data.csv" file in the working directory then the code below will create one
    # if there already si a "billing_data.csv" file, then the code below will add a line to it
    
    observeEvent(input$save, {
      
      # below are a series of objects created from the visit context information (location, visit_type, scope type, age) from the sidebar
      # these statements combine to automatically calculate the billing code and fee amount for the encounter
      # there is also a separate text string object created that shows the math of the calculations
      # there are some basic notes/caveats attached to some of the output that serve as reminders to prevent over/under billing an encounter and are removed manually before submitting my billing spreadsheet each week
      
      location_name <- if ((input$location == "clinic") | (input$location == "PRAC")) {
        "pediatric outpatient clinic"
      } else if (input$location == "COPC") {
        "pediatric urgent care clinic"
      } else if (input$location == "ER") {
        "emergency department"
      } else if (input$location == "inpatient") {
        "pediatrics ward"
      }
      
      diagnosis_code <- if (input$visit_type == "new") {
          if (input$location == "clinic" | input$location == "PRAC" | input$location == "COPC" | input$location == "ER") {
          paste("A265A")
        } else if (input$location == "inpatient") {
          paste("C265A")
        }
      } else if (input$visit_type == "follow up") {
        if (input$location == "clinic" | input$location == "PRAC" | input$location == "COPC" | input$location == "ER") {
          paste("A263A maybe w E078A (Ulcerative colitis (556) or Crohns disease (555) or Cirrhosis (571) or Chromosomal anomalies (578) or Developmental Delay (315) or Educational problems (902) or Autism (299) or Behavioural disorders (313) or Cerebral palsy (343) or Thrombocytopenia/Other hemorrhagic condition (287))")
        } else if (input$location == "inpatient") {
          paste("C263A maybe w E078A (Ulcerative colitis (556) or Crohns disease (555) or Cirrhosis (571) or Chromosomal anomalies (578) or Developmental Delay (315) or Educational problems (902) or Autism (299) or Behavioural disorders (313) or Cerebral palsy (343) or Thrombocytopenia/Other hemorrhagic condition (287))")
        }
      } else if (input$visit_type == "endoscopy") {
        if (input$scope_type == "Upper Endoscopy") {
          paste("Z399A")
        } else if (input$scope_type == "Upper Endoscopy and Colonoscopy") {
          paste("Z399A and Z496A and E740A and E741A and E747A and E705A")
        } else if (input$scope_type == "Colonoscopy") {
          paste("Z496A and E740A and E741A and E747A and E705A")
        } else if (input$scope_type == "Upper Endoscopy Foreign Body Removal") {
          paste("Z399A and E690A")
        }
      } else if (input$visit_type == "phone call") {
        paste("K731A (at least 10 min, not if transferring and not if consult done that day or next day)")
      }
      
      
      age_raw <- 
        if (is.na(input$dob)) {
          as.period(interval(start = "2010-01-01", end = input$encounter_date))
        } else {
          as.period(interval(start = input$dob, end = input$encounter_date))
        }
      
      fees_pre_age <- if (diagnosis_code == "A265A" | diagnosis_code == "C265A") {
        175.40
      } else if (diagnosis_code == "A263A maybe w E078A (Ulcerative colitis (556) or Crohns disease (555) or Cirrhosis (571) or Chromosomal anomalies (578) or Developmental Delay (315) or Educational problems (902) or Autism (299) or Behavioural disorders (313) or Cerebral palsy (343) or Thrombocytopenia/Other hemorrhagic condition (287))" | diagnosis_code == "C263 maybe w E078 (Ulcerative colitis (556) or Crohns disease (555) or Cirrhosis (571) or Chromosomal anomalies (578) or Developmental Delay (315) or Educational problems (902) or Autism (299) or Behavioural disorders (313) or Cerebral palsy (343) or Thrombocytopenia/Other hemorrhagic condition (287))") {
        80.05
      } else if (diagnosis_code == "Z399A") {
        92.50
      } else if (diagnosis_code == "Z399A and Z496A and E740A and E741A and E747A and E705A") {
        288.80
      } else if (diagnosis_code == "Z496A and E740A and E741A and E747A and E705A") {
        196.30
      } else if (diagnosis_code == "Z399A and E690A") {
        136.35
      } else if (diagnosis_code == "K731A (at least 10 min, not if transferring and not if consult done that day or next day)") {
        40.45
      }

      fees <- if (diagnosis_code == "K731A (at least 10 min, not if transferring and not if consult done that day or next day)") {
        fees_pre_age
      } else if (age_raw$year >= 16) {
        fees_pre_age
      } else if (age_raw$year >=5 && age_raw$year <16) {
        fees_pre_age*1.1
      } else if (age_raw$year >=2 && age_raw$year <5) {
        fees_pre_age*1.15
      } else if (age_raw$year >=1 && age_raw$year <2) {
        fees_pre_age*1.2
      } else if (age_raw$month >=1 && age_raw$year <1) {
        fees_pre_age*1.25
      } else if (age_raw$month <1 && age_raw$year <1) {
        fees_pre_age*1.3
      } else {
        fees_pre_age
      }
      
      # showing the math used to calculate billing fees
      
      my_math_text <- paste0(fees_pre_age, "*", fees/fees_pre_age)
      
      # chronic disease premium adds 50%, this is not included in the pre-calculated fees as it only applies to follow up visits
      
        if (file.exists(paste0(getwd(), "/billing_data.csv"))) {
          responses <- read_csv(paste0(getwd(), "/billing_data.csv"))
          this_patient <- t(as.data.frame(c(input$patient_name,
                                            input$mrn,
                                            paste(as.Date(input$encounter_date)),
                                            paste(as.Date(input$admission_date)),
                                            diagnosis_code,
                                            as.character(fees),
                                            1,
                                            location_name,
                                            input$referring_physician,
                                            my_math_text)))
          colnames(this_patient) <- c("patient_name",
                                      "cr",
                                      "service_date",
                                      "admit_date",
                                      "diagnosis_code",
                                      "fees",
                                      "units",
                                      "location",
                                      "referring_provider",
                                      "my_math")
          responses2 <- rbind(responses, this_patient)
          write_csv(responses2, file = paste0(getwd(), "/billing_data.csv"))
        } else {
          this_patient <- t(as.data.frame(c(input$patient_name,
                                            input$mrn,
                                            paste(as.Date(input$encounter_date)),
                                            paste(as.Date(input$admission_date)),
                                            diagnosis_code,
                                            as.character(fees),
                                            1,
                                            location_name,
                                            input$referring_physician,
                                            my_math_text)))
          colnames(this_patient) <- c("patient_name",
                                      "cr",
                                      "service_date",
                                      "admit_date",
                                      "diagnosis_code",
                                      "fees",
                                      "units",
                                      "location",
                                      "referring_provider",
                                      "my_math")
          this_patient <- as.data.frame(this_patient)
          write_csv(this_patient, file = paste0(getwd(), "/billing_data.csv"))
          }
      
    })
    }
  )

shinyApp(ui, server)
