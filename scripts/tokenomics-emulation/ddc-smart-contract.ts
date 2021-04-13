import { KeyringPair } from "@polkadot/keyring/types";
import { ExtrinsicStatus } from "@polkadot/types/interfaces";
import { EventRecord } from "@polkadot/types/interfaces";
import Network from "./network";
import { ContractPromise } from "@polkadot/api-contract";
import cere02Abi from "./contract/cere02-metadata.json";

class DdcSmartContract {
  private ddcContract: ContractPromise;

  constructor(private readonly config: any, private readonly network: Network) {
    const api = this.network.api;
    const cere02SCAddress = this.config.network.ddc_sc_address;
    this.ddcContract = new ContractPromise(api, cere02Abi, cere02SCAddress);
  }

  /**
   * Calls the report_metrics function in cere02 smart contract
   * @param sender Sender
   * @param dataRec Data Rec
   * @param dataRep Data Rep
   * @param reqRec Request Rec
   * @param reqRep Request Rep
   * @returns hash
   */
  public async ddcReportMetrics(
    sender: KeyringPair,
    dataRec: string,
    dataRep: string,
    reqRec: string,
    reqRep: string
  ) {
    console.log(
      `About to call report_metrics in ddc sm from ${sender.address}`
    );
    const gasLimit = +this.config.network.gas_limit;
    const value = +this.config.network.value;
    const txnObj = await this.ddcContract.tx.reportMetrics(
      { value, gasLimit },
      dataRec,
      dataRep,
      reqRec,
      reqRep
    );

    return new Promise((res, rej) => {
      txnObj
        .signAndSend(sender, Network.sendStatusCb.bind(this, res, rej))
        .catch((err) => rej(err));
    });
  }

}

export default DdcSmartContract;
