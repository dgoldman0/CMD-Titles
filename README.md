# World Builder Ecosystem

At the core of World Builder is a resource token called Kemet (KEM). This word was the ancient name of Egypt, and literally means black land, referring to the fertile soil of the Nile, which gave life to Egypt, just as KEM gives life to the World Builder project. The total supply of KEM can only be changed by a public vote and is otherwise fixed.

## Contact

Feel free to reach out to me if you have any questions or are looking to join this project.

Email: [contact@danielgoldman.us](mailto:contact@danielgoldman.us)

## Governance

Voting is done through a complex standard democratized system allowing anyone to submit a proposal and anyone with a specific voting right NFT to vote.

### Democratized Contract

The base contract that gives a level of governance functionality to our contracts. It includes a number of built in functions, including the ability to request a withdraw of ETH, ERC20, ERC721, or ERC1155 tokens.

### Titles

Titles act as the voting rights sytsem for the democratized interface that all World Builder DAOs utilize. There are different tiers of titles, with the lowest being the provincial title. Each title rank can have multiple functions, but the privincial title is the title which allows a user to cast one individual vote per proposition.

### VotingMachine

The VotingMachine base contract can be extended to create different functionality for new projects. 

The abstract contract Democratized is extended by all the World Builder DAOs. It can use an alternative voting system if desired. The DefaultDemocratized contract includes a link to the common VotingMachine which is connected to the Titles system. All Democratized systems, by default, allow for voting on withdrawing ERC20, ERC721, and ERC1155 assets.

#### Propositions

Voting occurs through propositions. Democratized contracts each have their own options for initiating a request to do something, which generates a proposition in the voting machine. Whether the proposition passes or not depends on a number of conditions that can be sent by the Democratized contract.

- threshold: The percentage of yes votes necessary for the proposition to pass (usually 500000)
## Forge

KEM is a resource token in the sense that it is used to "forge" additional tokens for all the projects related to our ecosystem. As a resource token, it grows in value as more child projects are added to the ecosystem. The forge consists of individual DAO contracts with a standard interface for minting new tokens. KEM is given to the DAO in return for minting the DAO's native token, which can serve a number of functions. However, the DAO itself is controlled by the Titles system.

# MultiERC20Forgable Standard

Aside from a very basic shared interface, World Builder also has the MultiERC20Forgable standard. This interface includes functions to add additional resources beyond KEM, for projects that would like to accept other project tokens in return for their own. These functions can be useful for DAOs that want to accumulate tokens from projects related to their objective.

## Core Projects

### [Promote.Health](https://promote.health/)

Promote.Health is a global health intiative seeking to improve access to health services, including prevantative/nutritional care, and promote the development of new medical treatments.

### [Project Curate](https://github.com/dgoldman0/CUR-NFTs#readme)

Project Curate's foundation mission is to support the preservation and development of art, in all its forms, from physical to digital, as well as preserve human knowledge in general.

### Arcadium

Arcadium is our entertainment focused branch. The goal of Arcadium is to help foster eSports on web3 platforms and overall increase access to entertainment, and make entertainment more beneficial to society.
