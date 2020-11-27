#!/bin/bash/



echo "---- Indexing ----"
tabix -p vcf equus_caballus3.vcf
samtools faidx Equus_caballus.EquCab3.0.dna.toplevel.fa
java -jar gatk-4.1.6.0/gatk-package-4.1.6.0-local.jar CreateSequenceDictionary -R Equus_caballus.EquCab3.0.dna.toplevel.fa



for bamf in $(ls ./samples/ | egrep -i 'After_[0-9].bam')
do 

echo "Working with file $bamf"

base=$(basename -s .bam $bamf)

echo "---- ADDING READ GROUP ----"
java -jar gatk-4.1.6.0/gatk-package-4.1.6.0-local.jar AddOrReplaceReadGroups -I samples3/${base}.bam -O samples3/${base}_RGA.bam -RGID 1 -RGLB lib1 -RGPL illumina -RGPU unit1 -RGSM 20

echo "SORTING BY COORDINATES..."
java -Djava.io.tmpdir=tmp -jar gatk-4.1.6.0/gatk-package-4.1.6.0-local.jar SortSam -I samples3/${base}RGA.bam -O samples3/${base}_sorted.bam --CREATE_INDEX true -SO coordinate 

echo "MARKING DUPLICATES..."
java -jar gatk-4.1.6.0/gatk-package-4.1.6.0-local.jar MarkDuplicates -I samples3/${base}_sorted.bam -O samples3/${base}_marked.bam --CREATE_INDEX true -M samples3/${base}_metrics.txt

echo "HAPLOTYPE CALLER... "
java -Xmx4g -jar gatk-4.1.6.0/gatk-package-4.1.6.0-local.jar HaplotypeCaller -R Equus_caballus.EquCab3.0.dna.toplevel.fa -D equus_caballus3.vcf -I samples3/${base}_marked.bam -O output3/${base}_gvcf.g.vcf.gz -ERC GVCF

echo "GENOTYPE CALLER..."
java -Xmx4g -jar gatk-4.1.6.0/gatk-package-4.1.6.0-local.jar GenotypeGVCFs -R Equus_caballus.EquCab3.0.dna.toplevel.fa -D equus_caballus3.vcf -V output3/${base}_gvcf.g.vcf.gz -O output3/${base}_raw.vcf.gz

 echo "SELECTING SNP..."
java -Xmx4g -jar gatk-4.1.6.0/gatk-package-4.1.6.0-local.jar SelectVariants -R Equus_caballus.EquCab3.0.dna.toplevel.fa -V output3/sample_1/${base}_raw.vcf.gz --select-type-to-include SNP -O output3/${base}_SNP.vcf.gz

 echo "FILTERING..."
java -jar gatk-4.1.6.0/gatk-package-4.1.6.0-local.jar VariantFiltration -R Equus_caballus.EquCab3.0.dna.toplevel.fa -V output3/${base}_SNP.vcf.gz -O output3/${base}_filtered.vcf.gz --filter-expression "QD < 2.0 || FS > 60.0 || MQ < 40.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0 || SOR > 4.0" --filter-name "SNPbasic"

done
