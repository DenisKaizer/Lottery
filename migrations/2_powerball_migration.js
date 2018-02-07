var Token = artifacts.require("Token");
var LotteryFactory = artifacts.require("LotteryFactory");
var Lottery = artifacts.require("Lottery");


module.exports = function(deployer) {


    deployer.deploy(Token).then(function(){
        return deployer.deploy(LotteryFactory, Token.address);
    });
};