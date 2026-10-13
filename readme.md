# Work Hours

A native iOS app that replaces my "Work Hours Record" Excel sheet. Pick a month, enter daily values, and the app calculates the hours for you. Everything is stored on the device and works offline.

## Features
- Month and year picker, with saved months loaded automatically
- Daily entry for **AB, BL, HT, CH**: a number, **Check**, **Free**, or **Krank**
- Automatic daily total and monthly totals
- Real month lengths (28/29/30/31), or a fixed 30-row mode like the original sheet
- Records overview showing which months have data
- Export to **Excel (.xlsx)**, **PDF** and **CSV**
- Dark theme, animated splash screen, custom app icon
- Autosave. Nothing is deleted without a confirmation.

## Calculation rules
| Entry | Hours |
|---|---|
| Free or Krank (any cell of the day) | 0 |
| Check (any cell of the day) | 8
