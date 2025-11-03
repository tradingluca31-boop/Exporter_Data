//+------------------------------------------------------------------+
//|                        MultiSymbol_HistoricalData_Exporter.mq5   |
//|                                                                  |
//|   Export historical data for multiple symbols since 2008        |
//+------------------------------------------------------------------+
#property copyright "Historical Data Exporter"
#property version   "1.00"
#property script_show_inputs

//--- Input parameters
input datetime StartDate = D'2008.01.01 00:00:00';  // Date de début
input datetime EndDate = 0;                          // Date de fin (0 = aujourd'hui)
input ENUM_TIMEFRAMES Timeframe = PERIOD_D1;        // Timeframe
input string OutputFolder = "HistoricalData";        // Dossier de sortie
input bool AddLocalTime = false;                     // Ajouter heure locale

//--- List of symbols to export
string Symbols[] = {
   "XAUUSD",
   "USDJPY",
   "XAUXAG",
   "XAGUSD",
   "USTBOND.TR",
   "BRENT.CMD",
   "JPN.IDX",
   "USA500.IDX",
   "USA30.IDX",
   "USATECH.IDX",
   "VOL.IDX",
   "EURUSD",
   "DOLLAR.IDX"
};

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("========================================");
   Print("Multi-Symbol Historical Data Exporter");
   Print("========================================");
   Print("Start Date: ", TimeToString(StartDate, TIME_DATE));

   datetime endDate = (EndDate == 0) ? TimeCurrent() : EndDate;
   Print("End Date: ", TimeToString(endDate, TIME_DATE));
   Print("Timeframe: ", EnumToString(Timeframe));
   Print("Output Folder: MQL5/Files/", OutputFolder);
   Print("Number of symbols: ", ArraySize(Symbols));
   Print("========================================\n");

   // Create output folder
   if(!CreateFolder(OutputFolder))
   {
      Print("ERROR: Cannot create folder: ", OutputFolder);
      return;
   }

   int totalSymbols = ArraySize(Symbols);
   int successCount = 0;
   int failedCount = 0;

   // Process each symbol
   for(int i = 0; i < totalSymbols; i++)
   {
      string symbol = Symbols[i];
      Print("\n[", (i+1), "/", totalSymbols, "] Processing ", symbol, "...");

      if(ExportSymbolData(symbol, StartDate, endDate, Timeframe, OutputFolder))
      {
         successCount++;
         Print("✓ ", symbol, " exported successfully!");
      }
      else
      {
         failedCount++;
         Print("✗ ", symbol, " export FAILED!");
      }
   }

   // Summary
   Print("\n========================================");
   Print("EXPORT SUMMARY");
   Print("========================================");
   Print("Total symbols: ", totalSymbols);
   Print("Successfully exported: ", successCount);
   Print("Failed: ", failedCount);
   Print("========================================");

   if(successCount > 0)
   {
      Print("\n✓ Files location: MQL5/Files/", OutputFolder, "/");
      Print("✓ You can now use these CSV files for analysis!");
   }
}

//+------------------------------------------------------------------+
//| Export data for a single symbol                                  |
//+------------------------------------------------------------------+
bool ExportSymbolData(string symbol, datetime startDate, datetime endDate,
                      ENUM_TIMEFRAMES timeframe, string folder)
{
   // Check if symbol exists
   if(!SymbolSelect(symbol, true))
   {
      Print("  ERROR: Symbol ", symbol, " not found in Market Watch");
      return false;
   }

   // Request historical data
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   int copied = CopyRates(symbol, timeframe, startDate, endDate, rates);

   if(copied <= 0)
   {
      Print("  ERROR: No data available for ", symbol);
      Print("  Error code: ", GetLastError());
      return false;
   }

   Print("  → ", copied, " bars loaded");

   // Create filename with current date
   string currentDate = TimeToString(TimeCurrent(), TIME_DATE);
   StringReplace(currentDate, ".", "");
   string filename = folder + "/" + symbol + "_Historical_2008_" + currentDate + ".csv";

   // Open file for writing
   int fileHandle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_ANSI, ";");

   if(fileHandle == INVALID_HANDLE)
   {
      Print("  ERROR: Cannot create file ", filename);
      Print("  Error code: ", GetLastError());
      return false;
   }

   // Write CSV header
   FileWrite(fileHandle, "DateTime", "Open", "High", "Low", "Close", "Volume", "Spread");

   // Write data with progress indication
   int progressStep = MathMax(1, copied / 20); // Show progress every 5%

   for(int i = copied - 1; i >= 0; i--) // Write from oldest to newest
   {
      string dateTime = TimeToString(rates[i].time, TIME_DATE|TIME_MINUTES|TIME_SECONDS);

      // Get spread (may not be available for all symbols)
      double spread = 0;
      if(SymbolInfoInteger(symbol, SYMBOL_SPREAD) > 0)
         spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);

      FileWrite(fileHandle,
                dateTime,
                DoubleToString(rates[i].open, _Digits),
                DoubleToString(rates[i].high, _Digits),
                DoubleToString(rates[i].low, _Digits),
                DoubleToString(rates[i].close, _Digits),
                IntegerToString(rates[i].tick_volume),
                DoubleToString(spread, 0));

      // Show progress
      if((copied - i) % progressStep == 0)
      {
         double progress = (double)(copied - i) / copied * 100.0;
         Print("  Progress: ", DoubleToString(progress, 1), "%");
      }
   }

   FileClose(fileHandle);

   Print("  → File saved: ", filename);
   Print("  → Total bars written: ", copied);

   return true;
}

//+------------------------------------------------------------------+
//| Create folder if it doesn't exist                                |
//+------------------------------------------------------------------+
bool CreateFolder(string folderName)
{
   // Try to create folder (will succeed if it doesn't exist)
   ResetLastError();

   // Create a test file to check if folder exists/can be created
   int testHandle = FileOpen(folderName + "/test.tmp", FILE_WRITE|FILE_TXT);

   if(testHandle == INVALID_HANDLE)
   {
      int error = GetLastError();
      if(error != 0)
      {
         Print("Cannot access/create folder: ", folderName, " Error: ", error);
         return false;
      }
   }
   else
   {
      FileClose(testHandle);
      FileDelete(folderName + "/test.tmp");
   }

   return true;
}
//+------------------------------------------------------------------+
