from brownie import network, accounts, config
from brownie.network.account import Account

LOCAL_BLOCKCHAIN_ENVIRONMENTS = ["development"]


def get_account(index: int = None, id=None) -> Account:
    if index:
        return accounts[index]
    if id:
        return accounts.load(id)
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        return accounts[0]
    return accounts.add(config["wallets"]["from_key"])
