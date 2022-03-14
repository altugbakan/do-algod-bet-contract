from brownie import Bet, config, network
from brownie.network.account import Account
from datetime import datetime

from scripts.helpful_scripts import get_account


def deploy(account: Account = get_account()):
    return Bet.deploy(
        config["networks"][network.show_active()]["price_feed"],
        config["networks"][network.show_active()]["bet_token"],
        1_000_000 * 10 ** 18,  # 1 million dollars
        datetime.strptime("13/3/2023", "%d/%m/%Y").timestamp(),  # March 13th, 2023
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
