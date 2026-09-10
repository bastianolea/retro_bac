# Development of open-access application Retro-BAC for retrograde extrapolation alcohol calculation

_Authors:_

Espinoza Cruz, Carlos (1,4), Moreno Paz, José (1), Gómez Olmos, Yolanda (2) Caselles Gil, José (3)

1: Medico Legal Service of Copiapó, Chile. 
2: Department of Statistics, Faculty of Sciences of University of the Bio Bio, Chile. 
3: Service of Pharmacy, University Hospital of Fuenlabrada, Madrid, Spain.
4: University of Santiago de Compostela, Santiago De Compostela, Spain. 

## Introduction

Retrograde extrapolation alcohol calculation is frequently requested to forensic toxicology laboratories. In these cases, the blood alcohol concentration (BAC) is used as a reference value. In 2018, Labay and Logan called for creating consensus standards for conducting retrograde extrapolations of BAC to guarantee a scientific foundation for such estimates and their usage in judicial scenarios(1), LeBeau and Limoges in response to this request in 2024, “we announced an effort within the OSAC for Forensic Science and the Academy Standards Board (ASB) to develop such a consensus approach. In June 2024, ANSI/ASB 122, First Edition, was published.”(2,3). Currently using programming languages tools are created to support the work in the forensic area.

## Objective
The objective was to develop an application in R Shiny for the retrograde extrapolation alcohol calculation.

## Methods

Calculations were performed following the ANSI/ASB Best Practice Recommendation 122, 1st Ed. 2024 guidelines(3). 

Tests were carried out with results of post-absorptive real cases. The basic calculation for retrograde extrapolation it is expressed as:

𝐴𝐶_inc = 𝐴𝐶_test + (𝛽 x 𝑇)

𝐴𝐶_inc: estimated alcohol concentration at the time of the incident (g/L).
𝐴𝐶_test: measured alcohol concentration (g/L)
𝛽: elimination rate (g/L/hour)
𝑇: time between incident and time of breath test/blood draw (hours).

## Results

When using the application in reals cases, it was observed that its tool calculates the alcohol range of the individual using an alcohol concentration at a given point in time and estimates what the concentration would have been at an earlier time based on the BAC value and the times reported in the case background.

The calculations performed by the tool are visualized in real time, by applying the white box concept. In addition, the application provides a graph explaining the timeline of BAC of the case and a downloadable report with estimated information serves as registration documentation.

## Conclusion

The application developed in Retro-BAC for the retrograde extrapolation calculation provide the alcohol range in subjects post absorptive, permits a friendly environment for results, and helps to deliver relevant information based on a consensus and updated guideline, with the possibility of generating automatic reports.

The next step for this tool will be to have a Spanish language version to increase its scope, as well as to extend its use to other calculations incorporated in the guidelines used as reference.

## References
1. Labay L. and Logan B. (2018) Call for a Scientific Consensus Regarding the Application of Retrograde Extrapolation to Determine Blood Alcohol Content in DUI Cases, J Forensic Sci, September 2018, Vol. 63, No. 5.2.
2. LeBeau MA. and Limoges JF. (2024) Answering the call for a scientific consensus regarding the application of retrograde extrapolation to determine blood alcohol content in DUI cases. J Forensic Sci.;69:1935.3.
3. Academy Standards Board. (2024) ANSI/ASB BPR 122 – Best Practice Recommendation for Performing Alcohol Calculations in Forensic Toxicology, first edition.

## Acknowledgments
- To Soc. Bastián Olea Herrera for you support in this project.
- To Toxicology Consensus Body of the AAFS Standards Board.
- To Forensic Toxicology Subcommittee of the Organization of Scientific Area Committees (OSAC) for Forensic Science.