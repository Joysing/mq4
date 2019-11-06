//+------------------------------------------------------------------+
//|                           60 EMA profit indicator.mq4   Ver. 1.0 |
//|                                         Copyright (c) Henry Zhao |
//|                                              shinetrip@yahoo.com |
//|                                                 April 5~22, 2010 |
//+------------------------------------------------------------------+
#property  indicator_separate_window
#property  indicator_buffers 2
#property  indicator_color1 LimeGreen
#property  indicator_color2 SteelBlue

extern int number_of_bars=10000;  // works on how many bars. use smaller number to save CPU's work
extern bool show_on_point1=false;  // true: show profit/loss on entry point;  false: show profit/loss on exit point
extern int ma_period=60;  // EMA's period

double buffer1[];
double buffer2[];
double MyPoint;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   MyPoint=0.0001;
   if(StringFind(Symbol(),"JPY",3)==3) MyPoint=0.01;
   if(StringFind(Symbol(),"XAU",0)==0) MyPoint=0.1;
   if(StringFind(Symbol(),"XAG",0)==0) MyPoint=0.01;

   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);
   SetIndexBuffer(0,buffer1);

   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID);
   SetIndexBuffer(1,buffer2);

   SetLevelStyle(STYLE_DOT,1,LightGray);
   SetLevelValue(0,0);
   SetLevelValue(1,100);
   SetLevelValue(2,200);

   return(0);
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int start()
  {
   int limit,i;
   double ma,prv_ma,last_price,temp;
   int last_loc;

   limit=Bars;
   if(limit>number_of_bars) limit=number_of_bars;

   last_loc=limit-ma_period;
   last_price=Close[limit-ma_period];

   for(i=limit-ma_period; i>0; i--)
     {
      ma=iMA(NULL,0,ma_period,0,MODE_EMA,PRICE_CLOSE,i);
      prv_ma=iMA(NULL,0,ma_period,0,MODE_EMA,PRICE_CLOSE,i+1);
      if(show_on_point1==false) last_loc=i;
      if(Close[i]>ma && Close[i+1]<=prv_ma){ buffer1[last_loc]=-(Close[i]-last_price)/MyPoint; last_price=Close[i]; last_loc=i;}
      else if(Close[i]<ma && Close[i+1]>=prv_ma){ buffer1[last_loc]=(Close[i]-last_price)/MyPoint; last_price=Close[i]; last_loc=i;}
      else buffer1[i]=0;
     }

   buffer2[limit-ma_period+1]=0;
   for(i=limit-ma_period; i>0; i--)
     {
      temp=0;
      if(buffer1[i]<0) temp=temp-buffer1[i]; else temp=temp+buffer1[i];
      buffer2[i]=buffer2[i+1]+temp/3;
      if(buffer1[i]>80) buffer2[i]=0;
     }

   return(0);
  }
//+------------------------------------------------------------------+
