# Process for creating the ecosystem.

1. Deploy VotingMachine contract.
2. In code, set DefaultDemocratized voting contract to deployed voting machine address.
3. Deploy Titles contract.
4. Set voting rights contract to address of voting machine to address of deployed titles contract.
5. Deploy kem contract.
6. In cmd code, set address of resource token, currently left blank as address(0), as deployed kem contract 
7. Deploy cmd contract.
8. Set cmd address in titles to the deployed cmd address.
9. Repeat steps 6 and 7 for other core tokens like PHC.
10. In code, set appropriate details in faucet contracts.
11. Deploy faucet contracts.