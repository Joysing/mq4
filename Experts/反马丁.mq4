//+------------------------------------------------------------------+
//|                                                       反马丁.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Joysing"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define MAGICMA 20191102
//--- Inputs
extern int FastMAPeriod = 12;
extern int SlowMAPeriod = 26;
extern int SignalMAPeriod = 9;
extern int KdjPeriod=30;//KDJ周期
int ticket;
extern double Lots=0.01; //默认下单数量
extern int Max=10;//最大下单数量
extern double Pip=0.00001;//下单点差
double cnt;
int maxWin=5;//最大连赢次数
int nowWin=0;//当前连赢次数

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ticket=0;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   Print("=====================================Hello World! deinit");

//----
   return(0);
  }
//本EA下单数量
int GetHoldingOrdersCount()
  {
   int Count=0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
           {
            Count+=1;
           }
        }
     }
   return(Count);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(GetHoldingOrdersCount()==0)
     {

      //ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,3,stopLoss,takeProfit,"Martin",MAGICMA,0,Red);
      CheckForOpen();


     }
   else
     {
      CheckForClose();
      
      if(GetHoldingOrdersCount()==0)
        {
         //找到上一个本EA已完成的订单
         for(int i=OrdersHistoryTotal(); i>=0; i--)
           {
            if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
              {
               if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
                 {
                     //如果上一个订单输了，马上在平仓点下单
                     if(OrderProfit()<0){
                        CheckForOpen();
                     }
                  break;
                 }
              }
           }
         
        }
     }
//---
  }
void CheckForOpen()
  {
   int    res;

//--- go trading only for first tiks of new bar
   if(Volume[0]>1)
      return;

   double Profit=-1;
//找到上一个本EA已完成的订单
   for(int i=OrdersHistoryTotal(); i>=0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
           {
            Profit = OrderProfit();
            break;
           }
        }
     }
   if(IsDIFFCrossDEA())
     {
      //如果上一次赢了，这次下单双倍数量，直到达到连赢次数或输了，连赢6次，账户最少要扛得住0.01*(2的5次方)=0.32手
      if(Profit>0)
        {
         Lots = Lots*2;
         nowWin=nowWin+1;
        }
      else
        {
         nowWin=0;
         Lots=0.01;
        }
      if(nowWin==maxWin)
        {
         nowWin=0;
         Lots=0.01;
        }
      res=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-300*Point,0,"",MAGICMA,0,Blue);
     }
   else
      if(IsDIFFTroughDEA())
        {
         if(Profit>0)
           {
            Lots = Lots*2;
            nowWin=nowWin+1;
           }
         else
           {
            nowWin=0;
            Lots=0.01;
           }
         if(nowWin==maxWin)
           {
            nowWin=0;
            Lots=0.01;
           }
         res=OrderSend(Symbol(),OP_SELL,Lots,Ask,3,Ask+300*Point,0,"",MAGICMA,0,Blue);
        }

//---
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckForClose()
  {
//--- go trading only for first tiks of new bar
   if(Volume[0]>1)
      return;
//---
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)
         break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol())
         continue;

      //--- check order type
      if(OrderType()==OP_BUY)
        {
         if(IsGoBack(OrderType(),OrderOpenPrice())||IsDIFFTroughDEA())
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("关闭订单失败：",GetLastError());
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(IsGoBack(OrderType(),OrderOpenPrice())||IsDIFFCrossDEA())
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("关闭订单失败：",GetLastError());
           }
         break;
        }
     }
//---
  }

//+------------------------------------------------------------------+
//| DIFF在0轴上面上穿DEA（金叉）                                            |
//+------------------------------------------------------------------+
bool IsDIFFCrossDEA()
  {
   int bars = 10;
   double DIFF[999]={0};
   double DEA[999]={0};
   double MACD[999]={0};
   double crossSignal[999]={0};
   int DIFFCrossIndex=-1;//DIFF上穿位置
   for(int i=0; DIFFCrossIndex==-1 && i<999; i++)
     {
      DIFF[i]=iCustom(NULL, 0, "MACDWithX",12,26,9,0,i);
      DEA[i]=iCustom(NULL, 0, "MACDWithX",12,26,9,1,i);
      MACD[i]=iCustom(NULL, 0, "MACDWithX",12,26,9,2,i);

      if(iCustom(NULL, 0, "MACDWithX",12,26,9,0,i)>0 && iCustom(NULL, 0, "MACDWithX",12,26,9,0,i+1)<0){//DIFF上穿位置
         DIFFCrossIndex=i;
         break;
      }
     }
    
    int SignalCount=0;//DIFF上穿位置 ~ 信号位置 之间其他上穿信号的数量
     for(int i=0; i<DIFFCrossIndex;i++){
      crossSignal[i] = iCustom(NULL, 0, "MACDWithX",12,26,9,3,i+1);//多头信号,保存的是前一天的，因为今天的算不出来
      if(crossSignal[i]<2147483647)
            SignalCount++;
     }
      
double KDJ_D=iCustom(NULL, 0, "KDJ",3,3,KdjPeriod,2,0);
double KDJ_J=iCustom(NULL, 0, "KDJ",3,3,KdjPeriod,3,0);

      //2147483647 int最大数，未赋值时的默认值
      //DIFF上穿位置 ~ 信号位置 之间没有其他上穿信号，即说明这个信号是第一个
      if(crossSignal[0]<2147483647 //&& MathAbs(MACD[0])-MathAbs(MACD[1])>MathAbs(MACD[1])-MathAbs(MACD[2])
      &&crossSignal[0]>0//&&DIFF[0] > DIFF[1]&&DEA[0] > DEA[1]//&&SignalCount==1//&&iVolume(NULL,0,1)>1600
       && KDJ_J<99 && KDJ_D<80
      )
     {
      return(true);
     }
   else
     {
      return(false);
     }
  }

//+------------------------------------------------------------------+
//| DIFF下穿DEA（死叉）                                            |
//+------------------------------------------------------------------+
bool IsDIFFTroughDEA()
  {
   int bars = 10;
   double DIFF[999]={0};
   double DEA[999]={0};
   double MACD[999]={0};
   double throughSignal[999]={0};
   for(int i=0; i<bars; i++)
     {
      DIFF[i]=iCustom(NULL, 0, "MACDWithX",12,26,9,0,i);
      DEA[i]=iCustom(NULL, 0, "MACDWithX",12,26,9,1,i);
      MACD[i]=iCustom(NULL, 0, "MACDWithX",12,26,9,2,i);
     }

   int DIFFThroughIndex=-1;//DIFF下穿位置
   for(int i=0; DIFFThroughIndex==-1 && i<999; i++)
     {
      DIFF[i]=iCustom(NULL, 0, "MACDWithX",12,26,9,0,i);
      DEA[i]=iCustom(NULL, 0, "MACDWithX",12,26,9,1,i);
      MACD[i]=iCustom(NULL, 0, "MACDWithX",12,26,9,2,i);

      if(iCustom(NULL, 0, "MACDWithX",12,26,9,0,i)>0 && iCustom(NULL, 0, "MACDWithX",12,26,9,0,i+1)<0){//DIFF下穿位置
         DIFFThroughIndex=i;
         break;
      }
     }
      int SignalCount=0;//DIFF上穿位置 ~ 信号位置 之间其他上穿信号的数量
     for(int i=0; i<DIFFThroughIndex;i++){
      throughSignal[i] = iCustom(NULL, 0, "MACDWithX",12,26,9,4,i+1);//多头信号,保存的是前一天的，因为今天的算不出来
      if(throughSignal[i]<2147483647)
            SignalCount++;
     }
double KDJ_D=iCustom(NULL, 0, "KDJ",3,3,KdjPeriod,2,0);
double KDJ_J=iCustom(NULL, 0, "KDJ",3,3,KdjPeriod,3,0);
      //DIFF下穿位置 ~ 信号位置 之间没有其他上穿信号，即说明这个信号是第一个
      if(throughSignal[0]<2147483647// && MathAbs(MACD[0])-MathAbs(MACD[1])>MathAbs(MACD[1])-MathAbs(MACD[2])
      &&throughSignal[0]<0//&&DIFF[0] < DIFF[1]&&DEA[0] < DEA[1]&&throughSignal[0]<0//&&SignalCount==1
      &&KDJ_J>10
      )
     {
      return(true);
     }
   else
     {
      return(false);
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| 价格达到最大盈利点后回撤                                         |
//+------------------------------------------------------------------+
bool IsGoBack(int orderType,double orderPrice){
   int bars = 10;
   double DIFF[10]={0};
   double DEA[10]={0};
   double MACD[10]={0};
   for(int i=0; i<bars; i++)
     {
      DIFF[i]=iCustom(NULL, 0, "MACDWithX",12,26,9,0,i);
      DEA[i]=iCustom(NULL, 0, "MACDWithX",12,26,9,1,i);
      MACD[i]=iCustom(NULL, 0, "MACDWithX",12,26,9,2,i);
     }
   if(orderType==OP_SELL){//空单
      double maxProfit=orderPrice-Low[1];//昨天最大利润
      double nowProfit=orderPrice-Open[0];//当前利润
      if(maxProfit>0){
         double retreatRate=(maxProfit-nowProfit)/maxProfit;
         if(Open[0]>Close[1]+0.00002)//当前开盘价大于昨天收盘价1个点，且昨天为阴线，不加MACD成功率50%+
         { return(true);}
      }
   }else if(orderType==OP_BUY){//多单
      double maxProfit=High[1]-orderPrice;//昨天最大利润
      double nowProfit=Open[0]-orderPrice;//当前利润
      if(maxProfit>0){
         double retreatRate=(maxProfit-nowProfit)/maxProfit;
         if(Open[0]<Close[1]-0.00002)//当前开盘价小于昨天收盘价1个点，且昨天为阳线，不加MACD成功率50%+
         { return(true);}
      }
   }
   
   return(false);
}