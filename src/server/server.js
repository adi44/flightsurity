import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';

let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

let oracles =10;
//number of oracles defined
let registeredOracles =[];
//an array to store all the details of the orcales
let STATUS_CODES = [0, 10, 20, 30, 40, 50];

//function to register orcale
web3.eth.getAccounts((error, accounts) => {
  for(let i = 0; i < oracles; i++) {
    //using the method from contract to register the oracle on the blockchain. it will help the respective address to register for the oracle.
    flightSuretyApp.methods.registerOracle()
    .send({from: accounts[i], value: web3.utils.toWei("1",'ether'), gas: 9999999}, (error, result) => {
      flightSuretyApp.methods.getMyIndexes().call({from: accounts[i]}, (error, result) => {
      //a json object is created that will allow to keep details of orcale on the server side.
        let oracle = {
          address: accounts[i],
          index: result
        };
        //using the push operation to store the value of orcale.
        registeredOracles.push(oracle);
        console.log("ORACLE REGISTERED: " + JSON.stringify(oracle));
      });
    });
  };
});
/*here we are calling an event that will allow the client to get the detials of the oracle. Orcale would fetch details of the following flights
which will be emitted in the smart contract*/
flightSuretyApp.events.OracleRequest({
  //from oth block it will fetch all the details about the orcale information
  fromBlock: 0
}, function (error, event) {
  //following are the details of the flight
    let Index = event.returnValues.index;
    let airlineID = event.returnValues.airline;
    let flightID = event.returnValues.flight;
    let timestamp = event.returnValues.timestamp;
    let statusCode = STATUS_CODES[Math.floor(Math.random() * STATUS_CODES.length)]
    
    for(let i = 0; i < registeredOracles.length; i++) {
      if(registeredOracles[i].index.includes(index)) {
        flightSuretyApp.methods.submitOracleResponse(Index, airlineID, flightID, timestamp, statusCode)
        .send({from: registeredOracles[i].address, gas: 9999999}, (error, result) => {
          /* using this user would be able to share details with the smart contract*/
          console.log("FROM " + JSON.stringify(registeredOracles[i]) + "STATUS CODE: " + statusCode);
        });
      }
    }
});


const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


