SELECT t1.AcctName, t1.AcctCode, SUM(t0.SumApplied) AS VALOR FROM (

SELECT 
		t1.DocNum,
		t0.InvoiceId AS LineId,
		t1.DocType,
		t1.DocDate,
		t1.CardCode,
		t1.CardName,
		t1.DocTotal,
		t0.DocTransId,
		CASE
			WHEN t1.CashSum  > 0 THEN t1.CashAcct
			WHEN t1.CheckSum > 0 THEN '1.01.01.03.01'
			WHEN t1.TrsfrSum > 0 THEN t1.TrsfrAcct
			ELSE NULL
			END AS PayAcct,
		t3.Account AS AccountCode,
		(
			(t3.Debit - t3.Credit) --Saldo valor da linha da conta contábil
			/  (SELECT SUM(Debit) - SUM(Credit) --Dividido pelo saldo de todo lançamento contábil
					FROM JDT1 
					WHERE TransId = t0.DocTransId 
							AND Account <> '1.01.03.01.01'
				)
		) 
				* t0.SumApplied  --Multiplicado pelo valor da baixa 
				AS SumApplied,
		t3.OcrCode

FROM	RCT2 t0
		INNER JOIN ORCT t1 ON t1.DocNum	  = t0.DocNum		--Join cabeçalho pagamentos
		LEFT JOIN  OJDT t2 ON t2.TransId  = t0.DocTransId	--Join cabeçalho lançamentos ctbeis
		LEFT JOIN (SELECT TransId, Account, ProfitCode AS OcrCode, Debit, Credit -- Join cabeçalho lançamentos ctbeis
					FROM JDT1 WHERE Account <> '1.01.03.01.01') t3 ON t3.TransId = t2.TransId   --Filtrar créditos dos forncedores
		
WHERE		t1.Canceled = 'N'
		AND t1.CashSum + t1.CheckSum + t1.TrsfrSum > 0
		AND t1.DocType <> 'A'
		AND (t0.InvType <> 13 AND t0.InvType <> 14)

) t0 
INNER JOIN OACT t1 ON t0.AccountCode = t1.AcctCode
GROUP BY t1.AcctName, t1.AcctCode
ORDER BY VALOR DESC