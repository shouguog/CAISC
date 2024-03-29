# These functions are from the DENDRO project. We appreciate that they have made their code available for public use.
# (https://github.com/zhouzilu/DENDRO)

# Calculate and return distance matrix using X, N, Z, epi, and Pg
DENDRO.dist = function(X,N,Z,epi=0.01,show.progress=TRUE){
  cat("I am here\n")
  Pg = rowSums(Z,na.rm=T)/ncol(Z)
  dist1<-SNV.dist(N,X,Pg,epi,FALSE)#show.progress)
  dist = as.dist(dist1)
  dist = dist-min(dist)+1
  return(dist)
}

# Calculate and return distance matrix using X, N, Z, epi, and Pg
DENDRO.dist.v1 = function(X,N,Z,epi=0.01,show.progress=TRUE){
  Ng=rowSums(!is.na(Z))
  #Pg = cbind((rowSums(Z==0,na.rm=T)+1)/Ng,(rowSums(Z==1,na.rm=T)+1)/Ng,(rowSums(Z==2,na.rm=T)+1)/Ng)
  #Pg = Pg/rowSums(Pg)
  Pg = cbind((rowSums(N-X,na.rm=T)/rowSums(N,na.rm=T))^2,2*rowSums(X,na.rm=T)*rowSums(N-X,na.rm=T)/(rowSums(N,na.rm=T)^2),(rowSums(X,na.rm=T)/rowSums(N,na.rm=T))^2)
  dist = as.dist(SNV.dist.v1(N,X,Pg,epi,show.progress))
  dist = dist-min(dist)+1
  return(dist)
}

# Create dendrogram from distance matrix
DENDRO.cluster = function(dist,method='ward.D',plot=TRUE,label=NULL,type="phylogram",...){
  cat("I am here\n")
  clust=hclust(dist,method=method)
  if(plot){
    dend=as.dendrogram(clust)
    if(!is.null(label)){
      tip.color =
        colorspace::rainbow_hcl(
          length(unique(label))
        )[label]
      dend%>%as.phylo()%>%plot(type=type,main='DENDRO Result',tip.color=tip.color,...)
    }else{
      dend%>%as.phylo()%>%plot(type=type,main='DENDRO Result',...)
    }

    if(!is.null(label)){
      cols <- colorspace::rainbow_hcl(length(unique(label)))
      legend("topright", legend = 1:length(unique(label)),
             fill = cols, border = cols, bty = "n")
    }
  }
  return(clust)
}

# Create evolutionary tree from clusters
DENDRO.tree = function(Z_cluster,label_cluster=NULL){
  ret <- phyclust::phyclust.edist(t(Z_cluster), edist.model = .edist.model[4])
  if(is.null(label_cluster)){
    label_cluster=colorspace::rainbow_hcl(ncol(Z_cluster))
  }else{
    label_cluster=
      colorspace::rainbow_hcl(length(unique(label_cluster)))[label_cluster]
  }
  # summary(ret)
  # ret=log(ret)-min(log(ret))
  (ret.tree <- nj(ret))
  ret.tree$tip.label=colnames(Z_cluster)
  # plotnj(ret.tree,c(1,1,2,2,2,3,3),  show.tip.label = TRUE)

  phyclust::plotnj(ret.tree,tip.color=label_cluster,show.tip.label = TRUE)
  return(list(ret.tree=ret.tree, label_cluster=label_cluster))

}

# Filter out low expressed gene and high dropout cells based on read counts
FilterCellMutation = function(X,N,Z,Info=NULL,label=NULL,cut.off.VAF=0.05,
                              cut.off.sd=5,plot=TRUE){
  cat("I am here\n")
  filt = c(max(1,ncol(Z)*cut.off.VAF),(ncol(Z)*(1-cut.off.VAF)))
  filted_call = rowSums(Z,na.rm=T)>filt[1] & rowSums(Z,na.rm=T)<filt[2]
  cat('Filtering variants: ',sum(filted_call), ' out of ',nrow(Z),' variants retained; filter creatiera:',
      filt[1],'< # of cells detected <',filt[2],'\n')
  if(plot){
    par(mfrow=c(1,2))
    hist(rowSums(Z,na.rm=T), 20,
         main='Cell distribution \n for each mutation call',
         xlab ='Number of cells')
    abline(v=filt[1],col='red')
    abline(v=filt[2],col='red')
  }
  N = N[filted_call,]
  X = X[filted_call,]
  Z = Z[filted_call,]
  if(!is.null(Info)){
    Info = Info[filted_call,]
  }

  filt = c(pmax(0,round(mean(colSums(N))-cut.off.sd*sd(colSums(N)))),
           round(mean(colSums(N))+cut.off.sd*sd(colSums(N))))

  filted_cell = colSums(N)>filt[1] & colSums(N)<filt[2]
  cat('Filtering cells:',sum(filted_cell),' out of ',ncol(Z), 'cells retained; filter creatiera:',
      filt[1],'< total # of variants detected <',filt[2],'\n')
  if(plot){
    hist(colSums(N),20,main='Mutation distribution \n for each cell',
         xlab ='Number of mutations')
    abline(v=filt[1],col='red')
    abline(v=filt[2],col='red')
    par(mfrow=c(1,1))
  }
  N = N[,filted_cell]
  X = X[,filted_cell]
  Z = Z[,filted_cell]

  if(!is.null(label)){
    label=label[filted_cell]
  }

  return(list(X=X,N=N,Z=Z,Info=Info,label=label,filted_cell=filted_cell))
}

# Filter out low expressed gene and high dropout cells based on read counts
FilterCellMutation.v1 = function(X,N,Z,Info=NULL,label=NULL,cut.off.VAF=0.05,
                                 cut.off.sd=5,plot=TRUE){
  # filt = c(max(1,nrow(Z)*cut.off.VAF),(nrow(Z)*(1-cut.off.VAF)))
  ZnotNA=rowSums(!is.na(Z))/ncol(Z)
  filted_call = ZnotNA>cut.off.VAF
  cat('Variants with NA percentage less than', cut.off.VAF,': ',sum(filted_call),
      ' out of ',nrow(Z),'\n')
  N = N[filted_call,]
  X = X[filted_call,]
  Z = Z[filted_call,]
  if(!is.null(Info)){
    Info = Info[filted_call,]
  }


  VAF=rowSums(X,na.rm=T)/rowSums(N,na.rm=T)
  filted_call = VAF>cut.off.VAF & VAF<(1-cut.off.VAF)
  cat('Variants with VAF greater than', cut.off.VAF,' and less than ',
      (1-cut.off.VAF),': ',sum(filted_call),' out of ',nrow(Z),'\n')
  if(plot){
    par(mfrow=c(1,2))
    hist(rowSums(Z,na.rm=T), 20,
         main='Cell distribution \n for each mutation call',
         xlab ='Number of cells')
    abline(v=filt[1],col='red')
    abline(v=filt[2],col='red')
  }
  N = N[filted_call,]
  X = X[filted_call,]
  Z = Z[filted_call,]
  if(!is.null(Info)){
    Info = Info[filted_call,]
  }

  filt = c(pmax(0,round(mean(colSums(N))-cut.off.sd*sd(colSums(N)))),
           round(mean(colSums(N))+cut.off.sd*sd(colSums(N))))

  filted_cell = colSums(N)>filt[1] & colSums(N)<filt[2]
  cat('Number of cells with more than', filt[1],' and less ',filt[2],
      ' total read counts: ',sum(filted_cell),' out of ',ncol(Z),'\n')
  if(plot){
    hist(colSums(N),20,main='Mutation distribution \n for each cell',
         xlab ='Number of mutations')
    abline(v=filt[1],col='red')
    abline(v=filt[2],col='red')
    par(mfrow=c(1,1))
  }
  N = N[,filted_cell]
  X = X[,filted_cell]
  Z = Z[,filted_cell]

  if(!is.null(label)){
    label=label[filted_cell]
  }

  return(list(X=X,N=N,Z=Z,Info=Info,label=label,filted_cell=filted_cell))
}


# Combine read counts within each cluster and recalculate SNA based on likelihood
# model
DENDRO.recalculate = function(X,N,Info,DENDRO_label,
                              cluster.name=NULL,top=NULL,epi = 0.001,m=2){
  cat("I am here\n")
  if(is.null(cluster.name)){
    cluster.name=as.character(1:length(unique(DENDRO_label)))
  }

  N_cluster = mapply(function(k){
    sel=which(DENDRO_label==k)
    if(length(sel)==1){
      return(N[,sel])
    }
    return(rowSums(N[,sel],na.rm=T))
  },1:length(unique(DENDRO_label)),SIMPLIFY = T)
  colnames(N_cluster)=cluster.name
  #c('BC03Mix_1','BC03Mix_2','BC03LN_1','BC09_1','BC09_2')

  X_cluster = mapply(function(k){
    sel=which(DENDRO_label==k)
    if(length(sel)==1){
      return(X[,sel])
    }
    return(rowSums(X[,sel],na.rm=T))
  },1:length(unique(DENDRO_label)),SIMPLIFY = T)
  colnames(X_cluster)=colnames(N_cluster)

  lg = function(m,k,l,g,epi){
    -k*log(m)+l*log((m-g)*epi+g*(1-epi))+(k-l)*log((m-g)*(1-epi)+g*epi)
  }

  lg_array = array(data=NA,dim=c(dim(X_cluster),3))
  lg_array[,,1] = lg(m,N_cluster,N_cluster-X_cluster,0,epi)
  lg_array[,,2] = lg(m,N_cluster,N_cluster-X_cluster,1,epi)
  lg_array[,,3] = lg(m,N_cluster,N_cluster-X_cluster,2,epi)

  Z_cluster=apply(lg_array,c(1,2),function(x){
    if(all(is.na(x))){return(c(NA,NA))}
    else{return(c(which.max(x),max(x,na.rm=T)))}
  })
  Z_cluster_lg=Z_cluster[2,,]
  Z_cluster=Z_cluster[1,,]
  colnames(Z_cluster)=colnames(X_cluster)

  cat('Before QC, there are total ',nrow(Z_cluster),' mutations across ',
      ncol(Z_cluster),' subclones \n')

  # Filter
  not_sel=apply(Z_cluster,1,function(x)all(x[1] == x))
  not_sel[is.na(not_sel)]=FALSE
  Z_cluster = Z_cluster[!not_sel,]
  Z_cluster_lg = Z_cluster_lg[!not_sel,]
  N_cluster= N_cluster[!not_sel,]
  X_cluster= X_cluster[!not_sel,]
  Info_cluster=Info[!not_sel,]

  if(!is.null(top)){
    h_score = order(rowSums(abs(Z_cluster_lg)),decreasing = TRUE)[1:top]

    Z_cluster=Z_cluster[h_score,]
    hdlist_x_cluster_qc=dlist_x_cluster_qc[h_score,]
    N_cluster=N_cluster[h_score,]
    X_cluster=X_cluster[h_score,]
    Info_cluster=Info_cluster[h_score,]
  }
  cat('After QC, there are total ',nrow(Z_cluster),' mutations across ',
      ncol(Z_cluster),' subclones \n')

  return(list(X=X_cluster,N=N_cluster,
              Z=Z_cluster,Info=Info_cluster,
              lg=Z_cluster_lg))
}


# Calculate the intra-cluster divergence or intra-cluster sum of square error
# to decide optK Inputs are distnace matrix (d), hierachical cluster result (hc)
# and sup K (kmax)
DENDRO.icd = function(d,hc,kmax=10,plot=TRUE){
  sse.intra=mapply(function(k){
#    cat("I am here\n")
    c=dendextend::cutree(hc,k)
    d=as.matrix(d)
    sse.k=mapply(function(j){
      1/2*sum((d[c==j,c==j]))
    },unique(c))
    sse.nk=mapply(function(j){
      length(1/2*d[c==j,c==j])
    },unique(c))
    sse.k=sum(sse.k*sse.nk/sum(sse.nk))
    return(sse.k)
  },1:kmax)
  if(plot){
    plot(y=sse.intra,x=1:kmax,type='l')
  }
  return(sse.intra)
}

# Calculate the SNV distance given N (Total read count),
# X (Variants read counts), Pg (Mutation rate), and epi (Sequencing error rate)
SNV.dist <- function(N,X,Pg,epi= 0.001,show.progress) {
  cat("I am here\n")
  n <- ncol(N)
  d <- nrow(N)
  mu=rowMeans(X/N,na.rm=T)
  var=apply(X/N,1,function(x){var(x,na.rm=TRUE)})
  alpha <- ((1 - mu) * mu / var - 1 ) * mu
  beta <-  ((1 - mu) * mu / var - 1 ) * (1 - mu)
  not_sel = alpha<=0 | beta<=0 | is.na(alpha) | is.na(beta) |
    is.infinite(alpha) | is.infinite(beta)
  if(show.progress){
    cat(sum(not_sel),' of ',length(not_sel),' mutations are filtered out due
        to unestimatable Beta-binomial parameter.\n')
  }

  N=N[!not_sel,]
  X=X[!not_sel,]
  Pg=Pg[!not_sel]
  alpha=alpha[!not_sel]
  beta=beta[!not_sel]
  # precomputing logP(X|N,Z=0) & logP(X|N,Z=1)
  lPz0=sapply(seq(1,n),function(i){dbinom(X[,i],size=N[,i],prob=epi,log=T)})
  # lPz1=sapply(seq(1,n),function(i){linte_binomial(X[,i],N[,i])})
  # lPz1=log(1/(N+1))
  # dbb is faster
  lPz1=sapply(seq(1,n),function(i){TailRank::dbb(X[,i],N=N[,i],u=alpha,v=beta,log=TRUE)})

  lPg=log(Pg)
  l1Pg=log(1-Pg)
  lupiall=logSum_1(lPz0+l1Pg,lPz1+lPg)

  mat <- matrix(0, ncol = n, nrow = n)
  for(i in 1:nrow(mat)) {
    # cat(i,' ')
    mat[i,] <- SNV_distance_kernel_precompu(lPz0,lPz1,lPg,l1Pg,lupiall,i)
    if(show.progress){
      svMisc::progress(round(100*(i-1)/n))
      if (i == n) cat("Done!\n")
    }
  }
  colnames(mat) = colnames(X)
  return(mat)
  }

# Calculate the SNV distance given N (Total read count),
# X (Variants read counts), Pg (Mutation rate), and epi (Sequencing error rate)
# based on new formula. Here Pg is a Dx3 matrix where D is # of mutations
SNV.dist.v1 <- function(N,X,Pg,epi= 0.001,show.progress) {
  cat("I am here\n")
  n <- ncol(N)
  d <- nrow(N)
  mu=rowMeans(X/N,na.rm=T)
  var=apply(X/N,1,function(x){var(x,na.rm=TRUE)})
  alpha <- ((1 - mu) * mu / var - 1 ) * mu
  beta <-  ((1 - mu) * mu / var - 1 ) * (1 - mu)
  not_sel = alpha<=0 | beta<=0 | is.na(alpha) | is.na(beta) |
    is.infinite(alpha) | is.infinite(beta)
  if(show.progress){
    cat(sum(not_sel),' of ',length(not_sel),' mutations are filtered out due
        to unestimatable Beta-binomial parameter.\n')
  }

  N=N[!not_sel,]
  X=X[!not_sel,]
  Pg=Pg[!not_sel,]
  alpha=alpha[!not_sel]
  beta=beta[!not_sel]
  # precomputing logP(X|N,Z=0) & logP(X|N,Z=1)
  lPz0=sapply(seq(1,n),function(i){dbinom(X[,i],size=N[,i],prob=epi,log=TRUE)})
  # lPz1=sapply(seq(1,n),function(i){linte_binomial(X[,i],N[,i])})
  # lPz1=log(1/(N+1))
  # dbb is faster
  lPz1=sapply(seq(1,n),function(i){TailRank::dbb(X[,i],N=N[,i],u=alpha,v=beta,log=TRUE)})
  lPz2=sapply(seq(1,n),function(i){dbinom(N[,i]-X[,i],size=N[,i],prob=epi,log=TRUE)})

  lPg0=log(Pg[,1])
  lPg1=log(Pg[,2])
  lPg2=log(Pg[,3])
  lupiall=logSum_1(logSum_1(lPz0+lPg0,lPz1+lPg1),lPz2+lPg2)

  mat <- matrix(0, ncol = n, nrow = n)
  for(i in 1:nrow(mat)) {
    # cat(i,' ')
    mat[i,] <- SNV_distance_kernel_precompu.v2(lPz0,lPz1,lPz2,lPg0,lPg1,lPg2,lupiall,i)
    if(show.progress){
      svMisc::progress(round(100*(i-1)/n))
      if (i == n) cat("Done!\n")
    }
  }
  colnames(mat) = colnames(X)
  return(mat)
  # lupiall1=logSum_1(lPz0+lPg0,lPz1+lPg1)
  # lupiall2=logSum_1(lPz1+lPg1,lPz2+lPg2)

  # mat <- matrix(0, ncol = n, nrow = n)
  # for(i in 1:nrow(mat)) {
  #   # cat(i,' ')
  #   mat[i,] <- SNV_distance_kernel_precompu.v1(lPz0,lPz1,lPz2,lPg0,lPg1,lPg2,lupiall1,lupiall2,i)
  #   if(show.progress){
  #     svMisc::progress(round(100*(i-1)/n))
  #     if (i == n) cat("Done!\n")
  #     }
  # }
  # colnames(mat) = colnames(X)
  # return(mat)
  }

# Precompute factors used in divergence evalutation
SNV_distance_kernel_precompu.v2=function(lPz0,lPz1,lPz2,lPg0,lPg1,lPg2,lupiall,i){
  ldowni=logSum_1(logSum_1(lPz0[,i]+lPz0+lPg0,
                           lPz1[,i]+lPz1+lPg1),lPz2[,i]+lPz2+lPg2)

  lupi=logSum_1(lupiall[,i]+lupiall,ldowni)

  d=colSums(lupi-ldowni,na.rm=T)
  # d[d<0]=0
  return(d)
}

# Precompute factors used in divergence evalutation
SNV_distance_kernel_precompu.v1=function(lPz0,lPz1,lPz2,lPg0,lPg1,lPg2,lupiall1,lupiall2,i){
  ldowni=logSum_1(logSum_1(lPz0[,i]+lPz0+lPg0,
                           lPz1[,i]+lPz1+lPg1),lPz2[,i]+lPz2+lPg2)

  lupi=logSum_1(logSum_1(lupiall1[,i]+lupiall1,lupiall2[,i]+lupiall2),-(lPz1[,i]+lPz1+2*lPg1))

  lupi=logSum_1(lupi,ldowni)

  d=colSums(lupi-ldowni,na.rm=T)
  # d[d<0]=0
  return(d)
}

# Precompute factors used in divergence evalutation
SNV_distance_kernel_precompu=function(lPz0,lPz1,lPg,l1Pg,lupiall,i){
  cat("I am here\n")
  ldowni=logSum_1(lPz0[,i]+lPz0+l1Pg,
                  lPz1[,i]+lPz1+lPg)

  lupi=logSum_1(lupiall[,i]+lupiall,ldowni)

  d=colSums(lupi-ldowni,na.rm=T)
  # d[d<0]=0
  return(d)
}

# Quicker and more robust logSum, handle numeric overflow and underflow
logSum_1 = function(x,y){
  big=x
  big[x<y]=y[x<y]
  small=x
  small[!(x<y)]=y[!(x<y)]
  tmp=big+log(1+exp(small-big))
  tmp[x==-Inf & y==-Inf]=-Inf
  tmp[x==Inf & y==Inf]=Inf
  return(tmp)
}
