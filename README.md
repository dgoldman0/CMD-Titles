# World Builder Ecosystem

At the core of World Builder is a resource token called Kemet (KEM). This word was the ancient name of Egypt, and literally means black land, referring to the fertile soil of the Nile, which gave life to Egypt, just as KEM gives life to the World Builder project. The total supply of KEM can only be changed by a public vote and is otherwise fixed. 

## Governance

Voting is done through a complex standard democratized system allowing anyone to submit a proposal and anyone with a specific voting right NFT to vote. 

### Titles

Titles act as the voting rights sytsem for the democratized interface that all World Builder DAOs utilize. There are different tiers of titles, with the lowest being the provincial title. Each title rank can have multiple functions, but the privincial title is the title which allows a user to cast one individual vote per proposition.

### VotingMachine

The VotingMachine base contract can be extended to create different functionality for new projects. Users vote for propositions through the Voting Machine.

## Democratized Contract

The abstract contract Democratized is extended by all the World Builder DAOs. It can use an alternative voting system if desired. The DefaultDemocratized contract includes a link to the common VotingMachine which is connected to the Titles system. All Democratized systems, by default, allow for voting on withdrawing ERC20, ERC721, and ERC1155 assets.

## Forge

KEM is a resource token in the sense that it is used to "forge" additional tokens for all the projects related to our ecosystem. As a resource token, it grows in value as more child projects are added to the ecosystem. The forge consists of individual DAO contracts with a standard interface for minting new tokens. KEM is given to the DAO in return for minting the DAO's native token, which can serve a number of functions. However, the DAO itself is controlled by the Titles system. 