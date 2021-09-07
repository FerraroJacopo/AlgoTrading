//+------------------------------------------------------------------+
//|                                                 Final(forse).mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include <Trade/Trade.mqh>
#include <Trade\SymbolInfo.mqh>

CTrade trade;


input float atrMultiplier=1;
input float RR=3;
input float riskPercentage = 1.0;


//+---------------
int OnInit()
  {
   //stochDefinition = iCustom(_Symbol,PERIOD_H1,"stochRsi",14,3,3,14,80,20);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

  }

void OnTick()
  {
  
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits); //Ask price
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits); //Bid price
  
   MqlRates priceInfo[]; //candles
   MqlRates weeklyInfo[]; //candles
   
   double atr[]; 
   double trendEma[];

   
   int averageTrueRangeDefination = iATR(_Symbol, _Period, 20);
   int emadefinition2 = iMA(_Symbol,_Period,200,0,MODE_SMA,PRICE_CLOSE);
   
   double val_low;
   double val_high;
   
   
   int val_index_low=iLowest(_Symbol,_Period,MODE_LOW,7,2);
   int val_index_high=iHighest(_Symbol,_Period,MODE_HIGH,7,2);
   
   val_low = iLow(_Symbol,_Period,val_index_low);
   val_high= iHigh(_Symbol,_Period,val_index_high);  

   ArraySetAsSeries(atr, true);
   ArraySetAsSeries(trendEma, true);

   CopyBuffer(averageTrueRangeDefination, 0, 0, 3, atr);
   CopyBuffer(emadefinition2, 0, 0, 3, trendEma);

   CopyRates(_Symbol, _Period, 0, 3, priceInfo);

   if(priceInfo[1].close < val_low && priceInfo[1].close > trendEma[1] && isNewBar()) {
            
            //risk management
            double PipValue=(((SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE))*Point())/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
            double stopLossPips=(atrMultiplier*atr[1])/Point();
            double totalLots=riskPercentage*AccountInfoDouble(ACCOUNT_EQUITY)/(PipValue*stopLossPips);
            totalLots=floor(totalLots*100)/100;
            
            
            //trade management
            double entryPrice = Ask;
            double sl = entryPrice - atrMultiplier * atr[1];
            double tp = entryPrice + RR*atrMultiplier * atr[1];
            double lotSize=1;
            if(_Symbol=="USDJPY" || _Symbol=="AUDJPY" || _Symbol=="EURJPY" || _Symbol=="NZDJPY"
            || _Symbol=="GBPJPY" || _Symbol=="CADJPY" || _Symbol=="CHFJPY" || _Symbol=="SGDJPY"
            ) {
            lotSize = totalLots; }
            else {
            lotSize = totalLots/100;
            }
            lotSize = NormalizeDouble(lotSize,2);
            
            
            trade.Buy(lotSize,_Symbol,Ask,sl,tp);         
        
        } 
         
 if(priceInfo[1].close > val_high && priceInfo[1].close < trendEma[1] && isNewBar() ) {
            
            //risk management
            double PipValue=(((SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE))*Point())/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
            double stopLossPips=(atrMultiplier*atr[1])/Point();
            double totalLots=riskPercentage*AccountInfoDouble(ACCOUNT_EQUITY)/(PipValue*stopLossPips);
            totalLots=floor(totalLots*100)/100;
            
            //trade management
            double entryPrice = Bid;
            double sl = entryPrice + atrMultiplier * atr[1] ;
            double tp = entryPrice - RR * atrMultiplier * atr[1];
            double lotSize=1;
            if(_Symbol=="USDJPY" || _Symbol=="AUDJPY" || _Symbol=="EURJPY" || _Symbol=="NZDJPY"
            || _Symbol=="GBPJPY" || _Symbol=="CADJPY" || _Symbol=="CHFJPY" || _Symbol=="SGDJPY") {
            lotSize = totalLots; }
            else {
            lotSize = totalLots/100;
            }
            lotSize = NormalizeDouble(lotSize,2);
            
            
            trade.Sell(lotSize,_Symbol,entryPrice,sl,tp);

   } 
   
CheckBreakEvenLong(Ask,Bid);
CheckBreakEvenShort(Ask,Bid);
   
}     


//true if isBullish, false if isBearish (previous daily candle close)
bool isBullish(MqlRates& priceInfo[]) {
   if(priceInfo[1].close > priceInfo[1].open) {
      return (true);
   }
   
   return (false);
}

void CheckBreakEvenLong(double Ask, double Bid)
   {
   
   for(int i = PositionsTotal()-1; i>=0; i--)
   {
      string symbol = PositionGetSymbol(i);
      
      if(_Symbol==symbol)
      {
      
         ulong positionTicket = PositionGetInteger(POSITION_TICKET);
         
         double entryPrice = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),_Digits);
         
         double tp = NormalizeDouble(PositionGetDouble(POSITION_TP),_Digits);
         
         double sl = NormalizeDouble(PositionGetDouble(POSITION_SL),_Digits);
         
         int type = PositionGetInteger(POSITION_TYPE); 
         
         
         if(type==POSITION_TYPE_BUY) {
    
            double breakEvenPrice = tp-(entryPrice - sl);
            
            
            if(Ask >= breakEvenPrice &&
            tp-Bid >= SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL) &&
            Bid-sl >= SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL) && sl != entryPrice)  
            {
            
               trade.PositionModify(positionTicket, entryPrice,tp);
               Print("Modify oder: "+ positionTicket + " with sl: " + entryPrice);
              
               
            }
      
      }
      
      } }}
      
      
void CheckBreakEvenShort(double Ask, double Bid)
   {
   
   for(int i = PositionsTotal()-1; i>=0; i--)
   {
      string symbol = PositionGetSymbol(i);
      
      if(_Symbol==symbol)
      {
      
         ulong positionTicket = PositionGetInteger(POSITION_TICKET);
         
         double entryPrice = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),_Digits);
         
         double tp = NormalizeDouble(PositionGetDouble(POSITION_TP),_Digits);
         
         double sl = NormalizeDouble(PositionGetDouble(POSITION_SL),_Digits);
         
         int type = PositionGetInteger(POSITION_TYPE); 
         
         if(type==POSITION_TYPE_SELL) {
         
            double breakEvenPrice = sl-(entryPrice - tp);
            
            if(Bid <= breakEvenPrice &&
            Ask-tp >= SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL) &&
            sl-Ask >= SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL) && sl!=entryPrice)  
            {
            
               trade.PositionModify(positionTicket, entryPrice,tp);
               Print("Modify oder: "+ positionTicket + " with sl: " + entryPrice);
            
            }
      
      }
      
      } }}   
 
bool longCross(double& K[], double& D[]) {

   if(K[1] > D[1] && K[2] < D[2]) return (true);
   if(K[2] > D[2] && K[3] < D[3]) return (true);
   if(K[3] > D[3] && K[4] < D[4]) return (true);

   
   return false; }
   
bool shortCross(double& K[], double& D[]) {

   if(K[1] < D[1] && K[2] > D[2]) return (true);
   if(K[2] < D[2] && K[3] > D[3]) return (true);
   if(K[3] < D[3] && K[4] > D[4]) return (true);

   
   return false; }
  
bool overSold(double& K[], double& D[]) {

   if(K[1] <= 20 && D[1] <= 20) return (true);
   if(K[2] <= 20 && D[2] <= 20) return (true);
   if(K[3] <= 20 && D[3] <= 20) return (true);

   
   return (false);
}


bool overBought(double& K[], double& D[]) {

   if(K[1] >= 80 && D[1] >= 80) return (true);
   if(K[2] >= 80 && D[2] >= 80) return (true);
   if(K[3] >= 80 && D[3] >= 80) return (true);

   
   return (false);
}


bool bullishEngulfing(MqlRates& priceInfo[]) {
   
   if(priceInfo[1].close > priceInfo[1].open && 
   priceInfo[1].close > priceInfo[2].open && priceInfo[2].close < priceInfo[2].open) {
      return (true);
   }
   
   return (false);


}


bool bearishEngulfing(MqlRates& priceInfo[]) {
   
   if(priceInfo[1].close < priceInfo[1].open && 
   priceInfo[1].close < priceInfo[2].open && priceInfo[2].close > priceInfo[2].open) {
      return (true);
   }
   
   return (false);


}






bool isNewBar()
  {
//--- memorize the time of opening of the last bar in the static variable
   static datetime last_time=0;
//--- current time
   datetime lastbar_time=SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);

//--- if it is the first call of the function
   if(last_time==0)
     {
      //--- set the time and exit
      last_time=lastbar_time;
      return(false);
     }

//--- if the time differs
   if(last_time!=lastbar_time)
     {
      //--- memorize the time and return true
      last_time=lastbar_time;
      return(true);
     }
//--- if we passed to this line, then the bar is not new; return false
   return(false);
  }
