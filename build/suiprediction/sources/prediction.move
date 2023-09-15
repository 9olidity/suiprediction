module suiprediction::prediction {
    use SupraOracle::SupraSValueFeed::{get_price, OracleHolder};
    use sui::clock::{Self, Clock};
    use sui::balance::Balance;
    use sui::sui::SUI;
    use sui::object::UID;
    use sui::tx_context;
    use sui::transfer;
    use sui::object;
    use sui::balance;


    struct  Rounds has key {
        id: UID,
        rounds: vector<Round>
    }

    struct Round has  store {
        epoch: u64,
        lockTimestamp: u64,
        closeTimestamp: u64,
        lockPrice: u128,
        closePrice: u128,
        totalAmount: Balance<SUI>,
        upAmount: u256, // balance
        downAmount: u256,
        upaddress: Table<address,u256>,
        downaddress: Table<address,u256>,
        upamount: u256, // user number
        downamount: u256,
        oracleCalled: bool,
        upordown: bool
    }

    struct BetInfo has store {
        amount: u128,
        claimed: bool
    }
    struct Epoch has key ,store {
        id: UID,
        currentEpoch: u64
    }

    fun init(ctx: &mut tx_context::TxContext) {
        transfer::share_object(Rounds {
            id: object::new(ctx),
            rounds: vector::empty()
        });
        transfer::share_object(Epoch {
            id: object::new(ctx),
            currentEpoch: 0
        });
    }



    public entry fun betUp(
        rounds: &mut Rounds,
        epoch: &mut Epoch,
        sui: Coin<SUI>,
        playnum: u64,
        ctx: &mut tx_context::TxContext
    ) {
        let round = vector::borrow_mut(&mut rounds.rounds,playnum);
        assert!(playnum == epoch.currentEpoch + 1,0);
        assert!(round.epoch == epoch.currentEpoch + 1,0); // You can only bet on the next round
        let addamount = coin::value(&sui);
        let sui_balance = coin::into_balance(sui);
        // balance::join(&mut round.totalAmount, sui_balance);
        let round = vector::borrow_mut(&mut rounds.rounds,playnum);
        balance::join(&mut round.totalAmount, sui_balance);
        round.upAmount = round.upAmount + (addamount as u256);
        round.upamount = round.upamount + 1;
        // vector::push_back(&mut round.upaddress,tx_context::sender(ctx));
        table::add(&mut round.upaddress,tx_context::sender(ctx),(addamount as u256));
    }

    public entry fun betDown(
        rounds: &mut Rounds,
        epoch: &mut Epoch,
        sui: Coin<SUI>,
        playnum: u64,
        ctx: &mut tx_context::TxContext
    ) {
        // assert!(round.epoch != epoch.currentEpoch,0);
        let round = vector::borrow_mut(&mut rounds.rounds,playnum);
        assert!(playnum == epoch.currentEpoch + 1,0);
        assert!(round.epoch == epoch.currentEpoch + 1,0);// You can only bet on the next round
        let addamount = coin::value(&sui);
        let sui_balance = coin::into_balance(sui);
        // balance::join(&mut round.totalAmount, sui_balance);
        let round = vector::borrow_mut(&mut rounds.rounds,playnum);
        balance::join(&mut round.totalAmount, sui_balance);
        round.downAmount = round.downAmount + (addamount as u256);
        round.downamount = round.downamount + 1;
        // vector::push_back(&mut round.downaddress,tx_context::sender(ctx));
        table::add(&mut round.downaddress,tx_context::sender(ctx),(addamount as u256));
    }

    // #[test_only]
    public entry fun startplay(rounds: &mut Rounds,epoch: &mut Epoch,clock: &Clock,ctx: &mut TxContext) {
        let firstround = Round {
            epoch: 0,
            lockTimestamp: clock::timestamp_ms(clock),
            closeTimestamp: clock::timestamp_ms(clock),
            lockPrice: 0,
            closePrice: 0,
            totalAmount: balance::zero<SUI>(),
            upAmount: 0,
            downAmount: 0,
            upaddress: table::new<address,u256>(ctx),
            downaddress: table::new<address,u256>(ctx),
            upamount: 0,
            downamount: 0,
            oracleCalled: false,
            upordown: false
        };
        vector::push_back(&mut rounds.rounds,firstround);
        // epoch.currentEpoch = epoch.currentEpoch + 1; //

        let secondround = Round {
            epoch: 1,
            lockTimestamp: clock::timestamp_ms(clock),
            closeTimestamp: 0,
            lockPrice: 0,
            closePrice: 1,
            totalAmount: balance::zero<SUI>(),
            upAmount: 0,
            downAmount: 0,
            upaddress: table::new<address,u256>(ctx),
            downaddress: table::new<address,u256>(ctx),
            upamount: 0,
            downamount: 0,
            oracleCalled: false,
            upordown: false
        };
        vector::push_back(&mut rounds.rounds,secondround);
        // epoch.currentEpoch = epoch.currentEpoch + 1;


    }

    public entry fun executeRound(
        rounds: &mut Rounds,
        currentEpoch: u64,
        epoch: &mut Epoch,
        oracle_holder: &OracleHolder, // 0xaa0315f0748c1f24ddb2b45f7939cff40f7a8104af5ccbc4a1d32f870c0b4105,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(currentEpoch == epoch.currentEpoch,0);
        let round = vector::borrow_mut(&mut rounds.rounds,currentEpoch);
        // debug::print(&round.epoch);
        // debug::print(&epoch.currentEpoch);
        let (value, decimal, oracle_timestamp, oracle_round) = get_price(oracle_holder, 90);

        assert!(value > 0,0);

        round.closePrice = value;
        round.closeTimestamp = clock::timestamp_ms(clock);



        // up wins
        if(round.closePrice > round.lockPrice) {
            // let rewardAmount =  balance::value(&round.upAmount) + balance::value(&round.downAmount);
            // coin::take(&mut round.totalAmount, 1, ctx)
            round.oracleCalled = true;
            round.upordown = true;

        };
        // down wins
        if(round.closePrice < round.lockPrice) {
            round.oracleCalled = true;
            round.upordown = false;
        };
        let nextround = Round {
            epoch: epoch.currentEpoch + 2,
            lockTimestamp: 0,
            closeTimestamp: 0,
            lockPrice: 0,
            closePrice: 0,
            totalAmount: balance::zero<SUI>(),
            upAmount: 0,
            downAmount: 0,
            upaddress: table::new<address,u256>(ctx),
            downaddress: table::new<address,u256>(ctx),
            upamount: 0,
            downamount: 0,
            oracleCalled: false,
            upordown: false
        };
        vector::push_back(&mut rounds.rounds,nextround);

        let round2 = vector::borrow_mut(&mut rounds.rounds,currentEpoch + 1 );
        round2.lockPrice = value;
        round2.lockTimestamp = clock::timestamp_ms(clock);


        epoch.currentEpoch = epoch.currentEpoch + 1;
    }

    public entry fun claim(
        rounds: &mut Rounds,
        playnum: u64,
        epoch: &mut Epoch,
        ctx: &mut TxContext
    ){
        let round = vector::borrow_mut(&mut rounds.rounds,playnum);
        assert!(round.oracleCalled,0);//
        if(round.upordown) {// up wins
            let to = &mut round.totalAmount;
            let userinput = *table::borrow(&round.upaddress,tx_context::sender(ctx));
            let reward = (userinput * round.downamount * 95   / round.upamount ) / 100 + userinput;
            let rewardcoin = coin::take(to, (reward as u64), ctx);
            transfer::public_transfer(rewardcoin, tx_context::sender(ctx));
            let success = table::contains<address, u256>(&round.upaddress,tx_context::sender(ctx));
            if (success) {
                table::remove(&mut round.upaddress,tx_context::sender(ctx));
            }
        }else{
            let to = &mut round.totalAmount;
            let userinput = *table::borrow(&round.downaddress,tx_context::sender(ctx));
            let reward = (userinput * round.upamount * 95  / round.downamount ) / 100 + userinput;
            let rewardcoin = coin::take(to, (reward as u64), ctx);
            transfer::public_transfer(rewardcoin, tx_context::sender(ctx));

            let success = table::contains<address, u256>(&round.downaddress,tx_context::sender(ctx));
            if (success) {
                table::remove(&mut round.downaddress,tx_context::sender(ctx));
            }
        }
    }
    public entry fun adminwithdraw(
        rounds: &mut Rounds,
        playnum: u256,
        ctx: &mut TxContext
    ) {
        let round = vector::borrow_mut(&mut rounds.rounds,(playnum as u64));
        let reward = balance::value(&mut round.totalAmount);
        let to = &mut round.totalAmount;
        let rewardcoin = coin::take(to, reward, ctx);
        transfer::public_transfer(rewardcoin, tx_context::sender(ctx));
    }
    // public entry fun getcurrent(epoch: &mut Epoch): u32 {
    //     epoch.currentEpoch
    // }
    //
    // public entry fun getupAmount(rounds: &mut Rounds,playnum: u256): u256 {
    //     let round = vector::borrow(&mut rounds.rounds,playnum);
    //     round.upAmount
    // }
    // public entry fun getdownAmount(rounds: &mut Rounds,playnum: u256): u256 {
    //     let round = vector::borrow(&mut rounds.rounds,playnum);
    //     round.downAmount
    // }
    //
    // public entry fun gettotalAmount(rounds: &mut Rounds,playnum: u256): u256 {
    //     let round = vector::borrow(&mut rounds.rounds,playnum);
    //     balance::value(&round.totalAmount)
    //     // balance::value(&round.upAmount) + balance::value(&round.downAmount)
    // }




    #[test_only]
    use sui::test_scenario;
    use sui::coin::Coin;
    use sui::coin;
    use std::vector;
    use sui::tx_context::TxContext;
    use std::debug;
    use sui::table::{Table, add};
    use sui::table;

    #[test]
    fun testpaly() {
        let owner = @0x99;
        let user1 = @0x991;
        let user2 = @0x992;
        let user3 = @0x993;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario,owner);
        {
            init(test_scenario::ctx(scenario))
        };

        test_scenario::next_tx(scenario,owner);
        {
            let rounds_val = test_scenario::take_shared<Rounds>(scenario);
            let round = &mut rounds_val;

            let epoch_val = test_scenario::take_shared<Epoch>(scenario);
            let epoch = &mut epoch_val;
            let ctx = test_scenario::ctx(scenario);
            // startplay(round,epoch,ctx);
            // assert!(getcurrent(epoch) == 1,0); // frist epoch
            test_scenario::return_shared(epoch_val);
            test_scenario::return_shared(rounds_val);
        };

        // test betup
        test_scenario::next_tx(scenario,user1);
        {
            let epoch_val = test_scenario::take_shared<Epoch>(scenario);
            let epoch = &mut epoch_val;
            let rounds_val = test_scenario::take_shared<Rounds>(scenario);
            let rounds = &mut rounds_val;
            let ctx = test_scenario::ctx(scenario);
            betUp(
                rounds,
                epoch,
                coin::mint_for_testing<SUI>(10, ctx),
                0,
                ctx
            );
            // assert!(getupAmount(rounds,0) == 10,0);
            test_scenario::return_shared(rounds_val);
            test_scenario::return_shared(epoch_val);
        };


        // test betDown
        test_scenario::next_tx(scenario,user2);
        {
            let epoch_val = test_scenario::take_shared<Epoch>(scenario);
            let epoch = &mut epoch_val;
            let rounds_val = test_scenario::take_shared<Rounds>(scenario);
            let rounds = &mut rounds_val;
            let ctx = test_scenario::ctx(scenario);
            betDown(
                rounds,
                epoch,
                coin::mint_for_testing<SUI>(10, ctx),
                0,
                ctx
            );
            // assert!(getdownAmount(rounds,0) == 10,0);
            // assert!(gettotalAmount(rounds,0) == 20,0);// up + down = 20
            test_scenario::return_shared(rounds_val);
            test_scenario::return_shared(epoch_val);
        };

        // up
        test_scenario::next_tx(scenario,user3);
        {
            let epoch_val = test_scenario::take_shared<Epoch>(scenario);
            let epoch = &mut epoch_val;
            let rounds_val = test_scenario::take_shared<Rounds>(scenario);
            let rounds = &mut rounds_val;
            let ctx = test_scenario::ctx(scenario);
            betUp(
                rounds,
                epoch,
                coin::mint_for_testing<SUI>(10, ctx),
                0,
                ctx
            );
            // assert!(getupAmount(rounds,0) == 20,0);
            test_scenario::return_shared(rounds_val);
            test_scenario::return_shared(epoch_val);
        };

        // In the first case, the bulls win
        //The administrator ends the current round and starts the next round
        test_scenario::next_tx(scenario,owner);
        {
            let epoch_val = test_scenario::take_shared<Epoch>(scenario);
            let epoch = &mut epoch_val;
            let rounds_val = test_scenario::take_shared<Rounds>(scenario);
            let rounds = &mut rounds_val;
            let ctx = test_scenario::ctx(scenario);

            // executeRound(rounds,0,epoch,ctx);
            // assert!(getdownAmount(rounds,1) == 0,0);
            // executeRoundfortest(rounds,0,epoch,ctx);
            // executeRoundfortest(rounds,1,epoch,ctx);

            test_scenario::return_shared(rounds_val);
            test_scenario::return_shared(epoch_val);
        };


        //Receive award
        test_scenario::next_tx(scenario,user1);
        {
            let epoch_val = test_scenario::take_shared<Epoch>(scenario);
            let epoch = &mut epoch_val;
            let rounds_val = test_scenario::take_shared<Rounds>(scenario);
            let rounds = &mut rounds_val;

            claim(rounds,1,epoch,test_scenario::ctx(scenario));

            test_scenario::return_shared(rounds_val);
            test_scenario::return_shared(epoch_val);
        };

        // test epoch.currentEpoch + 1
        // test_scenario::next_tx(scenario,owner);
        // {
        //     let epoch_val = test_scenario::take_shared<Epoch>(scenario);
        //     let epoch = &mut epoch_val;
        //     exe(epoch);
        //     assert!(getcurrent(epoch) == 2,0); // second epoch
        //     test_scenario::return_shared(epoch_val);
        // };

        test_scenario::end(scenario_val);
    }


}


// 0x95a6d8e8bc01d13fbae05e7383af760ba16369afee18ac99e992c682d254cbcb
// rounds
// 0xd419bd4eb57a5941c8996a5f27d5601bce3cce592c09ceccbc98f15a519468b1
//prediction
// 0xc794b130aa5410bb768a3cd7ab0f4219018844479acf04409ef20bab7fd106fb
//epoch
// orcel
// 0xaa0315f0748c1f24ddb2b45f7939cff40f7a8104af5ccbc4a1d32f870c0b4105


//           exec()            exec()
//               current(lock)      can bet
//  epoch = 2 |   epoch = 3     | epoch = 4   | epoch = 5
//  round = 2 |   round = 3     | round = 4   | round = 5

