Rounds是一个数组，存储每一轮比赛的内容

每一轮比赛的具体内容存在Round结构中

买的钱每次都存在totalAmount里面，upAmount这种只存储数字，不存储资产

Epoch这个结构体只存储当前的游戏轮数，为了买游戏时判断不是玩的过期轮数游戏或未来的轮数游戏

upAmount是看涨的所有资金，upamount是看涨的人数，便于最后分钱

betUP为看长

betDown为看跌


executeRound是一轮比赛结束，管理员调用开始新的一轮，并且判断这一轮是看涨获胜还是看跌获胜，并且分配奖励，奖励不直接发送给获胜者，要获胜者自己调用claim来提取之前获胜的每一轮奖励


// - ID: 0x8ed6f84d53710c569c27705104e0e26705b51dd5811b6e5d9c1466ee1a0a0152 , pridiction
// - ID: 0xd0c7325e733eb551dfd72678e5c83fa5dbd8e8ac66e158d8dfabeb4d16cfc5d6 , Epoch
// - ID: 0xfaa140e90a6624dd80240da3512b9d869832e1b2d589899a0e88368751d9d14c , Rounds
//
// sui client call --package 0x8ed6f84d53710c569c27705104e0e26705b51dd5811b6e5d9c1466ee1a0a0152  --module prediction --function betUp --gas-budget 1000000000 --args 0xfaa140e90a6624dd80240da3512b9d869832e1b2d589899a0e88368751d9d14c 0xd0c7325e733eb551dfd72678e5c83fa5dbd8e8ac66e158d8dfabeb4d16cfc5d6 0x3a281b90336c4a492c2990cfc9464eb085d2d7df17fb59b41c9cca2248ab1fef 0
// sui client split-coin --coin-id 0x3a281b90336c4a492c2990cfc9464eb085d2d7df17fb59b41c9cca2248ab1fef --amounts 3000 --gas-budget 1000


// 买大 https://suiexplorer.com/txblock/HmV9f58tJAytrZTQg4ePwGnWqfW3m8wmVKtDzQjsKdA6
// 结束当前轮，开启下一轮 https://suiexplorer.com/txblock/LqU3AWnWov2jeRFByvzP5gNLaBRWw1fmVGjpAcEEgeb
// 获胜者领奖  https://suiexplorer.com/txblock/iXfHpKiVydmEsnc6WEGyPLBo3pUnSxEYMVSWoVZSQWu