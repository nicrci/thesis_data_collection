## Overview
Data collection materials and scripts for my master's thesis, "Contrasting Development Models: A Comparative Study of Chinese and Japanese Infrastructure Investments in Indonesia." Conducted R-based analysis and visualization of publicly available data from the AEI China Global Investment Tracker to examine Chinese overseas investment patterns, with particular application to research on Chinese investment in Indonesia; independently reviewed and validated AI-assisted code. 

## Research Focus
This project forms part of a broader research project examining foreign infrastructure investment in Indonesia. The analysis focuses specifically on the Chinese investment patterns that provide quantitative context for the broader research.

Specifically, this analysis examines the question: **What patterns can be observed in the scale and distribution of Chinese investment?** The analysis does not, on its own, examine the governance, financing structures, or implementation processes of individual infrastructure projects.

## Data
The original dataset is not included in this repository. Please refer to the original source for information on obtaining the underlying dataset.
[American Enterprise Institute's China Global Investment Tracker](https://www.aei.org/china-global-investment-tracker/)

All figures and tables in `static/` are the author's own calculations based on the China Global Investment Tracker. The regional groupings used in this repository (e.g., Southeast Asia, Oceania, and MENA) are defined by the author and differ from AEI's regional classifications; therefore, the regional totals presented here may not match those published by AEI.

The analysis scripts in `scripts/` demonstrate the data processing and analytical workflow used in the project.

## Methodology
The analysis was conducted using R and involved:
1. Data acquisition
2. Data cleaning
3. Descriptive analysis
4. Visualization
5. Validation of analytical outputs

AI-assisted tools (Gemini CLI) were used during coding. All generated code was reviewed, tested, and validated by the researcher.

## Repository Structure

```text
thesis_data_collection/
├── scripts/           # R scripts for data cleaning, processing, and analysis
├── static/            # Generated figures, tables, and analysis outputs
├── summary/           # Documentation for the summary CSVs
└── README.md          # Project overview, methodology, and key findings
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Analysis | R (tidyverse), Python |
| Visualization | R (ggplot2, etc.) |

## Key Findings
- **Investment is concentrated in a small number of sectors.** 
  The analysis shows that almost 1 trillion and 500 billion USD combined investment and construction of observed activity types were directed toward the energy and transportation sectors, respectively. This indicates a strong concentration of investment activity (as shown in sector_investment.png).

- **Investment patterns vary substantially across countries.**
  Indonesia being the independent variable country examined in this thesis, the analysis is further broken down into regions. Southeast Asia presents itself as a region that China has heavily invested in in the energy and transport sectors. The analysis shows Indonesia as the Southeast Asian country receiving the largest share of investment, with Singapore being the second (as shown in country_investment.png).

- **Investment activity changed over time.**
  The analysis identifies a notable shift in regional investment proportion for Southeast Asia after 2016, suggesting changes in the composition of investment. Middle East and North Africa (shortened MENA) does not see a noticeable progressive pattern in their regional investment shift, indicating a strategic investment shift from China (as pictured in regional_shift_share_v2.png).

- **The results highlight differences in investment strategies.**
  The observed patterns suggest that China has Southeast Asia as one of its largest contenders for receiving its investment, with implications for policy relevance. The progressive spike of regional investment shift starting from 2016 is paralleled with the signing of the ACFTA (or ASEAN-China Free Trade Area) 2.0, which further refined market access, rules of origin, and trade facilitation between Southeast Asian countries and China.

## Reproducibility
The analysis scripts are provided in the scripts/ directory and document the main stages of data processing, analysis, and visualization.

The original China Global Investment Tracker dataset is not included in this repository. To reproduce the analysis, users should obtain the relevant data directly from the American Enterprise Institute and follow the data-processing steps documented in the repository.

Because the original dataset is not distributed with this repository, the results may not be fully reproducible from the repository alone. Differences in dataset versions or subsequent updates to the source data may also affect the results.

The repository therefore focuses on documenting the analytical workflow rather than redistributing the underlying dataset.

## Limitations
Data-wise, because the dataset may be updated over time, results obtained using a different version of the data may differ from those presented here.

Scope-wise, the analysis primarily identifies patterns and distributions in the available data. It does not establish causal relationships between Chinese investment and particular economic or political outcomes.

## Citation
American Enterprise Institute and The Heritage Foundation. "China Global Investment Tracker." Accessed March 2025. https://www.aei.org/china-global-investment-tracker/.

## Version Control

This project is maintained via Git. Use `git log` to see recent changes.
