// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test,console} from "../../lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant TXAMOUNT = 0.1 ether;
    uint256 constant STARTING_BAL = 10 ether;
    uint256 constant GAS_PRICE = 1;
    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER,STARTING_BAL);
    }
    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(),5e18);
    }
    function testOwnerIsMsgSender() public {
        console.logAddress(fundMe.getOwner());
        console.logAddress(msg.sender);
        assertEq(fundMe.getOwner(),msg.sender);
    }
    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version,4);
    }
    function testFundFailsWithoutEnoughEth() public  {
        vm.expectRevert(); // next line should revert
        fundMe.fund();
    }
    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //Next Tx will be sent by user
        fundMe.fund{value: TXAMOUNT}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded,TXAMOUNT);
    }
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value:TXAMOUNT}();
        address funder = fundMe.getFunder(0);
        assertEq(funder,USER);
    }
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: TXAMOUNT}();
        _;
    }
    function testOnlyOwnerCanWithdraw() public funded{
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }
    function testWithdrawWithASingleFunder() public funded {
        //Arrange

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(startingFundMeBalance+startingOwnerBalance,endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numbersOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i<numbersOfFunders; i++) {
            //vm.prank() new address
            //vm.deal new address
            hoax(address(i),TXAMOUNT);
            fundMe.fund{value:TXAMOUNT}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        assert(address(fundMe).balance==0);
        assert(startingFundMeBalance+startingOwnerBalance==fundMe.getOwner().balance);
    }
    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numbersOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i<numbersOfFunders; i++) {
            //vm.prank() new address
            //vm.deal new address
            hoax(address(i),TXAMOUNT);
            fundMe.fund{value:TXAMOUNT}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        //assert
        assert(address(fundMe).balance==0);
        assert(startingFundMeBalance+startingOwnerBalance==fundMe.getOwner().balance);
    }

    
}