# Blocklords Banner Sales

[Blocklords](https://blocklords.com) is a medieval grand strategy MMO game developed by MetaKings studio and published by Seascape Network.

Blocklords has various NFTs that will be used in the game. The first type of the NFT is a Hero NFT (It's not yet deployed). The second type of the NFT is a Banner NFT. 

This smartcontract repository represents the Banner NFT Sales that will be going on Ethereum mainnet. 


> Banner NFT Sales is going to be on Ethereum > mainnet. While NFT themselves are planned to be minted on [Immutable X](https://www.immutable.com/).

## Banner NFTs

Banner's have a `quality` parameter that represents their rarity. There are five different qualities of the banners.

> Note, that Banner NFTs are stored in another repository.

Banner NFTs might be used in the game, to represent the guilds or dynasties. For now, they are used in the NFT Sales.


## Banner sales

In the Banner NFT Sales, banners are sold in Banner packs. Each pack consisting random banners of the different quality. There are three different banner pack categories:

* Golden Banner Packs - More chance to Gold Banner NFTs
* Silver Banner Packs - More chance to Silver Banner NFTs
* Bronze Banner Packs - Less likely to get Gold Banner, more likely the common Banner NFTs.

> The aim of the Banner NFTs is to collect them and use in certain combination to mint Hero NFTs.

> NFT Sales are going to be in ETH currency.

### Flow
Let's go through the NFT Sales flow from the user's perspective:

* User `Joe` registers on the Blocklords website using his email/password. 
* Then `Joe` links his `Metamask` wallet to his Blocklords website account. He also creates an **Immutable X** account based on his `Metamask` account.
* After registration, `Joe` whitelists himself by completing the social tasks.

> Any whitelisted user get's the Bronze Banner pack. *These banner packs are minted by the NFT Sales backend on Immutable X for the user.* Users can check their NFT packs on their profile page. And they can unpack them.

After whitelisting, user's has the three options:

1. The 2D version of the Blocklords was built in 2018 and stopped in 2020. See the [NFTs of the Blocklords 2d on Opensea](https://opensea.io/collection/blocklords). On the NFT Sales page, user's who has the old Blocklords NFTs can burn their old heroes in exchange for the Silver banner packs.

2. Every `n` hours, the Blocklords website, allows user's to buy Bronze Banner Packs for fixed price. The price is set by the server backend.

3. Any whitelisted user can join to the Lottery.

#### Lottery

Whole lottery Season is divided into the Lottery rounds.
Each Lottery round goes for **7 days**.
Any whitelisted user can bid ETH into the smartcontract.
They can bid multiple times within the round.

*The amount of Gold Banner packs are limited for every round, and announced to everyone on the website.*

At the end of the first five days of every round, three highest bidders win Golden Banner Packs out of 10 gold banner packs.
The remaining 7 gold banner packs are lotteryfied in the next two days.
Other bidders can see that they did not win the 3 banner pack guarantee and so they have the remaining two days to either bid more or withdraw. 

They can only withdraw their ETH during those two days. After the lottery happens their ETH is sent to us and they either win or they lose.
After the two days, users could get 1 of 7 gold banner packs if they won the lottery and the ETH is sent to us
They can get silver packs if they lose the lottery and the ETH is sent to us.

> The start of the round resets the gaols of the previous round.

# Smartcontract architecture
The **Banner NFT Minting** is going to be on Immutable X, therefore it's not stored in this repository.

This repository consists One smartcontract that's built from two components:
* `Lottery.sol` - Keeps the lottery described in [Lottery flow](####Lottery).
* `Main.sol` - Main smartcontract that extends the `Lottery.sol` with the two other options desribed on [Flow](###Flow) section. Namely, purchasing Bronze NFTs and burning Old NFTs.


## Lottery.sol

* `start` - started by smartcontract owner. The method starts the NFT Sales, by defining how many rounds it has, the duration of every round, and bidding period to win Golden Banner Packs.

---
### User callable functions

* `bid` - Payable, user's can bid. It's active from the start and end time of the round. It accepts the Signature Proof from the Server, to validate that the user is whitelisted.

* `highestClaim` - Called only after end of the 5 days out of 7 days, and onward, whenever user wants to claim his NFT. This will expose an event for the backend to trigger minting of Gold Banner pack on Immutable X

* `withdraw` - Called on day 6, 7 of 7 days round. Withdraws the ETH that user bidded.

* `silverForMonster` - Reference to the Witcher game. User lost the lottery after end of the round. He can get the Silver Banner Pack.

* `win` - User won the lottery, and can get Golden Banner Pack.