//+------------------------------------------------------------------+
//|                                                          KDJ.mq4 |
//|                                                        Joysing   |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Joysing"
#property link      "mailto:im@Joysing.cc"
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_buffers 5
#property indicator_level1 50

#property indicator_color1 0x00ff00
#property indicator_color2 Red
#property indicator_color3 Yellow
#property indicator_color4 0Xffccff
#property indicator_color5 MediumSlateBlue

//---- input parameters
input int       KDJPeriod=30;//RSV周期
input int       M1=3;//RSV的M1天移动平均值
input int       M2=3;//K的M2天移动平均值

//---- buffers
double RSV[],K[],D[],J[],KDC[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
    //---- name for DataWindow and indicator subwindow label
    string short_name;
   short_name="KDJ("+KDJPeriod+","+M1+","+M2+") ";
   IndicatorShortName(short_name);
   SetIndexLabel(1,"RSV");
   SetIndexLabel(2,"K");
   SetIndexLabel(3,"D");
   SetIndexLabel(4,"J");
   SetIndexLabel(5,"KDC");
//----
//---- indicators
//---- drawing settings
   IndicatorDigits(Digits-2);       //set小数精度两位
   //----
   SetIndexStyle(0,DRAW_NONE);
   SetIndexBuffer(0,RSV);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,K);
   SetIndexStyle(2,DRAW_LINE);
   SetIndexBuffer(2,D);
   SetIndexStyle(3,DRAW_LINE);
   SetIndexBuffer(3,J);
   SetIndexStyle(4,DRAW_HISTOGRAM);
   SetIndexBuffer(4,KDC);
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int counted_bars=IndicatorCounted();
//----
   int i;
   if(Bars<=KDJPeriod) return(0);
//----
   i=Bars-counted_bars-1;
   double MaxHigh=0,MinLow=0;
   while(i>=0)
     {
      MaxHigh=High[iHighest(NULL,0,MODE_HIGH,KDJPeriod,i)];//KDJPeriod周期内最高价
      MinLow=Low[iLowest(NULL,0,MODE_LOW,KDJPeriod,i)];//KDJPeriod周期内最低价
      RSV[i]=(Close[i]-MinLow)/(MaxHigh-MinLow)*100;
      i--;
     } 
      Ksma();
      Dsma();
//---- //
  if(counted_bars>0) counted_bars--;
  for(i=Bars-counted_bars-1;i>=0;i--)
   {
      J[i]=3*K[i]-2*D[i];
      if(J[i]<0) J[i]=0;
      if(J[i]>100) J[i]=100;
	   KDC[i]=K[i]-D[i];
      }   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| 计算D值                                                          |
//+------------------------------------------------------------------+
void Dsma()
  {
   double sum=0;
   int ExtCountedBars=IndicatorCounted();
   int pos=Bars-IndicatorCounted()-1;
//---- initial accumulation
   if(pos<M2) pos=M2;
   for(int i=1;i<M2;i++,pos--)
   sum+=K[pos];
//---- main calculation loop
   while(pos>=0)
     {
      sum+=K[pos];                   //加上最新的K值
      D[pos]=sum/M2;
 	   sum-=K[pos+M2-1];
 	   pos--;
     }
   }
//+------------------------------------------------------------------+
//| 计算K值                                                          |
//+------------------------------------------------------------------+
void Ksma()
  {
   double sum=0;
   int ExtCountedBars=IndicatorCounted();
   int pos=Bars-IndicatorCounted()-1;
   //---- initial accumulation
   if(pos<M1) pos=M1;
   for(int i=1;i<M1;i++,pos--)
       sum+=RSV[pos];
   //---- main calculation loop
   while(pos>=0)
     {
      sum+=RSV[pos];                    //加上最新的RSV[]的值
	   K[pos]=sum/M1;
      sum-=RSV[pos+M1-1];
 	   pos--;
     }
  }
//+------------------------------------------------------------------+

