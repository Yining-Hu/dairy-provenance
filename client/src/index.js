const countSupermarkets = async (sm, contract) => {
  sm = await contract.methods.countSupermarkets().call();
  $("h2").html(sm);
};

const addSupermarkets = (sm, contract, accounts) => {
  let input;
  $("#input").on("change", (e) => {
    input = e.target.value;
  });
  $("#form").on("submit", async (e) => {
    e.preventDefault();
    await contract.methods
      .addSupermarkets(input)
      .send({ from: accounts[0], gas: 40000 });
      countSupermarkets(sm, contract);
  });
};

async function autoInvoiceApp() {
  const web3 = await getWeb3();
  const accounts = await web3.eth.getAccounts();
  const contract = await getContract(web3);
  let sm;

  countSupermarkets(sm, contract);
  addSupermarkets(sm, contract, accounts);
}

autoInvoiceApp();
