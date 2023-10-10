## 项目介绍

Sui-Prediction 旨在为用户提供一个有趣而具有潜在收益的投注平台。该平台允许用户通过对未来5分钟内 SUI 加密货币价格进行投注来参与游戏。用户根据自己的预期判断 SUI 价格是否会上涨或下跌，并将资金投注在相应的选项上。同样也是 Sui 区块链上的第一个去中心化预测市场（DPM）的实现，在未来计划通过添加额外的市场供用户预测。 用户将能够对现实世界的事件进行投注，包括但不限于体育和现实事件。 

项目推特: https://twitter.com/suiprediction


## 在线demo

https://prediction-sui.vercel.app/ 


![](https://pbs.twimg.com/media/F7FqCCnboAAn-RO?format=jpg&name=large)


## 代码细节

Rounds是一个数组，存储每一轮比赛的内容

每一轮比赛的具体内容存在Round结构中

买的钱每次都存在totalAmount里面，upAmount这种只存储数字，不存储资产

Epoch这个结构体只存储当前的游戏轮数，为了买游戏时判断不是玩的过期轮数游戏或未来的轮数游戏

upAmount是看涨的所有资金，upamount是看涨的人数，便于最后分钱

betUP为看长

betDown为看跌


executeRound是一轮比赛结束，管理员调用开始新的一轮，并且判断这一轮是看涨获胜还是看跌获胜，并且分配奖励，奖励不直接发送给获胜者，要获胜者自己调用claim来提取之前获胜的每一轮奖励

