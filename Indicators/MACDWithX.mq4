//+------------------------------------------------------------------+
//|                                                    MACDWithX.mq4 |
//|                                                         Joysing  |
//|                         http://www.frankie-prasetio.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Joysing"
#property link      "http://www.frankie-prasetio.blogspot.com"

#property indicator_separate_window
#property indicator_buffers 5
#property indicator_color1 Silver
#property indicator_color2 Yellow
#property indicator_color3 Red
#property indicator_color4 Lime
#property indicator_color5 Red
#property indicator_level1 0
//----
#define arrowsDisplacement 0.0001
//---- input parameters
extern int FastMAPeriod = 12;
extern int SlowMAPeriod = 26;
extern int SignalMAPeriod = 9;
//---- buffers
double MACDLineBuffer[];
double SignalLineBuffer[];
double HistogramBuffer[];
double bullishDivergence[];
double bearishDivergence[];
//---- variables
double alpha = 0;
double alpha_1 = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   IndicatorDigits(Digits + 1);
   //---- indicators
   SetIndexStyle(0, DRAW_LINE);
   SetIndexBuffer(0, MACDLineBuffer);
   SetIndexDrawBegin(0, SlowMAPeriod);
   SetIndexStyle(1, DRAW_LINE);
   SetIndexBuffer(1, SignalLineBuffer);
   SetIndexDrawBegin(1, SlowMAPeriod + SignalMAPeriod);
   SetIndexStyle(2, DRAW_HISTOGRAM, STYLE_SOLID,2);
   SetIndexBuffer(2, HistogramBuffer);
   SetIndexDrawBegin(2, SlowMAPeriod + SignalMAPeriod);
   SetIndexStyle(3, DRAW_ARROW);
   SetIndexArrow(3, 233);
   SetIndexBuffer(3, bullishDivergence);
   SetIndexStyle(4, DRAW_ARROW);
   SetIndexArrow(4, 234);
   SetIndexBuffer(4, bearishDivergence);
   SetIndexLabel(0, "DIFF");
   SetIndexLabel(1, "DEA");
   SetIndexLabel(2, "MACD");
   SetIndexLabel(3, "多头");
   SetIndexLabel(4, "空头");
   IndicatorShortName("MACDWithX(" + FastMAPeriod+"," + SlowMAPeriod + "," + SignalMAPeriod + ")");  
   //----
	  alpha = 2.0 / (SignalMAPeriod + 1.0);
	  alpha_1 = 1.0 - alpha;
   //----
   return(0);
}
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
     {
       string label = ObjectName(i);
       if(StringSubstr(label, 0, 19) != "MACD_DivergenceLine")
           continue;
       ObjectDelete(label);   
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int limit;
   int counted_bars = IndicatorCounted();
   //---- check for possible errors
   if(counted_bars < 0) 
       return(-1);
   //---- last counted bar will be recounted
   if(counted_bars > 0) 
       counted_bars--;
   limit = Bars - counted_bars;
   CalculateIndicator(counted_bars);

   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateIndicator(int countedBars)
  {
   for(int i = Bars - countedBars; i >= 0; i--)
     {
       CalculateMACD(i);
       CatchBullishDivergence(i);
       CatchBearishDivergence(i);
     }              
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateMACD(int i)
  {
   MACDLineBuffer[i] = iMA(NULL, 0, FastMAPeriod, 0, MODE_EMA, PRICE_CLOSE, i) - 
                       iMA(NULL, 0, SlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE, i);
   SignalLineBuffer[i] = alpha*MACDLineBuffer[i] + alpha_1*SignalLineBuffer[i+1];
   HistogramBuffer[i] = MACDLineBuffer[i] - SignalLineBuffer[i];      
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CatchBullishDivergence(int shift)
  {
   if(IsDIFFCrossDEA(shift) == true){
      bullishDivergence[shift] = MACDLineBuffer[shift] -  arrowsDisplacement;
   }
         
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CatchBearishDivergence(int shift)
  {
   if(IsDIFFTroughDEA(shift) == true){
      bearishDivergence[shift] = MACDLineBuffer[shift] +  arrowsDisplacement;
   }
      
  
  }

//+------------------------------------------------------------------+
//| DIFF上穿DEA（金叉）            
//| shift 当前位置                                |
//+------------------------------------------------------------------+
bool IsDIFFCrossDEA(int shift)
  {
   if(MACDLineBuffer[shift] >= SignalLineBuffer[shift] && MACDLineBuffer[shift+1] < SignalLineBuffer[shift+1] 
       //&&MACDLineBuffer[shift-1] > SignalLineBuffer[shift-1]
      )
      {
         return(true);
       }
   else {   
       return(false);
       }
  }
  
//+------------------------------------------------------------------+
//| DIFF下穿DEA（死叉）                                            |
//+------------------------------------------------------------------+
bool IsDIFFTroughDEA(int shift)
  {
   if(MACDLineBuffer[shift] <= SignalLineBuffer[shift] && MACDLineBuffer[shift+1] > SignalLineBuffer[shift+1]  
      //&&MACDLineBuffer[shift-1] < SignalLineBuffer[shift-1]
      )
      {
         return(true);
      }
   else{   
       return(false);
       }
  }