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
		t3.AccountCode,
		t3.LineTotal,
		(
			(t3.LineTotal --Valor do item
			/ (SELECT SUM(LineTotal)  --Valor total da NFE
				FROM INV1 
				WHERE DocEntry = t0.DocEntry)
			) * t0.SumApplied --Multiplicacao pelo valor da baixa (recebimento)
		)		AS SumApplied,
		t3.OcrCode,
		Distribuidor

FROM	RCT2 t0
		INNER JOIN ORCT t1 ON t1.DocNum	  = t0.DocNum		--Join cabeçalho pagamentos
		LEFT JOIN (SELECT DocEntry, AcctCode AS AccountCode, LineTotal, OcrCode FROM INV1 ) t3 ON t3.DocEntry = t0.DocEntry --Join linha nota fiscal
        LEFT JOIN (SELECT OINV.DocEntry, MAX(distribuidor.Distribuidor) AS Distribuidor FROM OINV
                    INNER JOIN (SELECT DocEntry, IIF(Usage=16,1,0) AS Distribuidor 
								FROM INV1) distribuidor ON distribuidor.DocEntry = OINV.DocEntry
                    			GROUP BY OINV.DocEntry) t4 ON t4.DocEntry = t0.DocEntry
		
WHERE		t1.Canceled = 'N'
		AND t1.CashSum + t1.CheckSum + t1.TrsfrSum > 0
		AND t1.DocType <> 'A'
        AND t4.Distribuidor <> 1
		AND t0.InvType = 13
		AND t1.DocNum = 586

) t0 
INNER JOIN OACT t1 ON t0.AccountCode = t1.AcctCode
GROUP BY t1.AcctName, t1.AcctCode
ORDER BY VALOR DESC