SELECT 
		t1.DocNum,
		t0.DocLine,
		t0.InvoiceId,
		t1.DocType,
		t1.DocDate,
		t1.CardCode,
		t1.CardName,
		t1.DocTotal,
		t0.DocTransId,
		CASE
			WHEN t1.CashAcct IS NOT NULL THEN t1.CashAcct
			WHEN t1.CheckSum > 0		 THEN '1.01.01.03.01'
			WHEN t1.BankAcct IS NOT NULL THEN t1.BankAcct
			ELSE t1.TrsfrAcct
			END AS PayAcct,
		t0.DocLine AS LineId,
		t3.Account AS AccountCode,
		t3.Debit,
		(SELECT SUM(Debit) - SUM(Credit) AS DebitTotal FROM JDT1 WHERE TransId = t0.DocTransId AND Account <> '2.01.01.01.01') AS BalanceTotal,
		((t3.Debit - t3.Credit) / (SELECT SUM(Debit) - SUM(Credit) AS BalanceTotal FROM JDT1 WHERE TransId = t0.DocTransId AND Account <> '2.01.01.01.01')) AS PercJdt,
		((t3.Debit - t3.Credit) / (SELECT SUM(Debit) - SUM(Credit) AS BalanceTotal FROM JDT1 WHERE TransId = t0.DocTransId AND Account <> '2.01.01.01.01')) * t0.SumApplied AS SumApplied_fix,
		t0.SumApplied,
		t3.OcrCode

FROM	VPM2 t0
		INNER JOIN OVPM t1 ON t1.DocNum	  = t0.DocNum		--JOIN CABECALHO
		LEFT JOIN  OJDT t2 ON t2.TransId  = t0.DocTransId	--JOIN CABECALHO LCTO CONTABIL
		LEFT JOIN (SELECT TransId, Account, ProfitCode AS OcrCode, Debit, Credit 
						FROM JDT1 WHERE Account <> '2.01.01.01.01') t3 ON t3.TransId = t2.TransId   --JOIN LINHA LCTO CONTABIL

WHERE		t1.Canceled = 'N'
		AND t1.DocType <> 'A'