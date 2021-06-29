import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as express from 'express';
import * as cors from 'cors';
import * as bodyParser from 'body-parser';
import { routesConfig } from './users/routes-config';

admin.initializeApp();

const app = express();
app.use(bodyParser.json());
app.use(cors({ origin: true }));
routesConfig(app)

export const api = functions.region('southamerica-east1').https.onRequest(app);

interface Contador{
    [key: string]: number; // IFoo is indexable; not a new property
}

export const alterarSelo = functions.region('southamerica-east1').firestore
.document('avaliacoes/{noticia}')
.onWrite(async (change, context) => {
    let aval = change.after.data() as any;
    console.log('SETANDO SELO DA NOTICIA: '+aval);
    if(!aval) return;

    let noticiaId = aval.noticia;
    var avaliacoes = await admin.firestore().collection('avaliacoes')
        .where('noticia', '==', noticiaId)
        .get();
    let contador: Contador ={};
    let max: string = '', maxi=0;
    for(let k of avaliacoes.docs) {
        let selo = k.data()['selo']['nome'] as string;
        let cont = contador[selo];
        if(cont) cont++; else cont=1;
        if(maxi < cont) { max=selo; maxi=cont }
    }

    console.log('SELO COM MAIS VOTOS: '+max);
    var selo = await admin.firestore().collection('selos').doc(max).get();
    if(selo.exists)
        admin.firestore().collection('noticias').doc(noticiaId).update({'selo': selo.data()});
});

export const primeiroAdmin = functions.region('southamerica-east1').auth.user().onCreate(async (user) => {
    let list = await admin.auth().listUsers(5);
    //functions.logger.info("Quantidade de usuários: "+list.users.length, {structuredData: true});
  
    if(list.users.length == 1){
        admin.auth().setCustomUserClaims(
            user.uid,
            {role: 'admin'}
        );
    }else{
        admin.auth().setCustomUserClaims(
            user.uid,
            {role: 'basic'}
        )
    }
});
