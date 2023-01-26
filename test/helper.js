const Web3 = require("web3");
const web3 = new Web3(`http://localhost:7545`);

advanceTimeAndBlock = async (time) => {
  await advanceTime(time);
  await advanceBlock();

  return Promise.resolve(web3.eth.getBlock("latest"));
};

advanceTime = (time) => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send(
      {
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [time],
        id: new Date().getTime(),
      },
      (err, result) => {
        if (err) {
          return reject(err);
        }
        return resolve(result);
      }
    );
  });
};

advanceBlock = () => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send(
      {
        jsonrpc: "2.0",
        method: "evm_mine",
        id: new Date().getTime(),
      },
      async (err, result) => {
        if (err) {
          return reject(err);
        }
        const newBlockHash = await web3.eth.getBlock("latest");

        return resolve(newBlockHash.hash);
      }
    );
  });
};

module.exports = {
  advanceTime,
  advanceBlock,
  advanceTimeAndBlock,
};
