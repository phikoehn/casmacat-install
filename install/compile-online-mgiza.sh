GCC=gcc
GPP=g++
LDFLAGS="-static"

MGIZA_DIR=/opt/moses/external/onlineMGIZA++_v0.2
SRC_DIR=$MGIZA_DIR/src
OBJ_DIR=$MGIZA_DIR/obj
BIN_DIR=$MGIZA_DIR/bin
INSTALL_DIR=/opt/moses/external/bin
BOOST_ROOT=/usr
BOOST_LIBRARYDIR=/usr/lib

BOOST_ROOT=/usr
BOOST_LIBRARYDIR=/usr/lib

mkdir -p $BIN_DIR
cd $BIN_DIR
rm d4norm hmmnorm mgiza plain2snt snt2cooc snt2coocrmp snt2plain symal mkcls

mkdir -p $OBJ_DIR
cd $OBJ_DIR
rm *.o libmgiza.a

$GPP -I$SRC_DIR -I$BOOST_ROOT/include -c -fPIC   \
 $SRC_DIR/alignment.cpp \
 $SRC_DIR/AlignTables.cpp \
 $SRC_DIR/ATables.cpp \
 $SRC_DIR/collCounts.cpp \
 $SRC_DIR/Dictionary.cpp \
 $SRC_DIR/ForwardBackward.cpp \
 $SRC_DIR/getSentence.cpp \
 $SRC_DIR/hmm.cpp \
 $SRC_DIR/HMMTables.cpp \
 $SRC_DIR/logprob.cpp \
 $SRC_DIR/model1.cpp \
 $SRC_DIR/model2.cpp \
 $SRC_DIR/model2to3.cpp \
 $SRC_DIR/model345-peg.cpp \
 $SRC_DIR/model3.cpp \
 $SRC_DIR/model3_viterbi.cpp \
 $SRC_DIR/model3_viterbi_with_tricks.cpp \
 $SRC_DIR/MoveSwapMatrix.cpp \
 $SRC_DIR/myassert.cpp \
 $SRC_DIR/NTables.cpp \
 $SRC_DIR/Parameter.cpp \
 $SRC_DIR/parse.cpp \
 $SRC_DIR/Perplexity.cpp \
 $SRC_DIR/reports.cpp \
 $SRC_DIR/SetArray.cpp \
 $SRC_DIR/transpair_model3.cpp \
 $SRC_DIR/transpair_model4.cpp \
 $SRC_DIR/transpair_model5.cpp \
 $SRC_DIR/TTables.cpp \
 $SRC_DIR/utility.cpp \
 $SRC_DIR/vocab.cpp

$GCC -c -fPIC $SRC_DIR/cmd.c

ar rvs libmgiza.a *.o

cd ..

$GPP -o $BIN_DIR/d4norm $SRC_DIR/d4norm.cxx      $LDFLAGS -I$BOOST_ROOT -I$SRC_DIR -L$OBJ_DIR -lmgiza  -L$BOOST_LIBRARYDIR -lboost_system -lboost_thread -lpthread 

$GPP -o $BIN_DIR/hmmnorm $SRC_DIR/hmmnorm.cxx    $LDFLAGS -I$BOOST_ROOT -I$SRC_DIR $OBJ_DIR/libmgiza.a  -L$BOOST_LIBRARYDIR -lboost_system -lboost_thread -lpthread 

$GPP -o $BIN_DIR/mgiza $SRC_DIR/main.cpp         $LDFLAGS -I$BOOST_ROOT -I$SRC_DIR $OBJ_DIR/libmgiza.a  -L$BOOST_LIBRARYDIR -lboost_system -lboost_thread -lpthread 

$GPP -o $BIN_DIR/plain2snt $SRC_DIR/plain2snt.cpp

$GPP -o $BIN_DIR/snt2cooc  $SRC_DIR/snt2cooc.cpp 

$GPP -o $BIN_DIR/snt2coocrmp $SRC_DIR/snt2cooc-reduce-mem-preprocess.cpp 

$GPP -o $BIN_DIR/snt2plain $SRC_DIR/snt2plain.cpp 

$GPP -o $BIN_DIR/symal $SRC_DIR/symal.cpp        $LDFLAGS -I$BOOST_ROOT -I$SRC_DIR $OBJ_DIR/libmgiza.a  -L$BOOST_LIBRARYDIR -lboost_system -lboost_thread -lpthread 

$GPP -I$SRC_DIR/mkcls  -o $BIN_DIR/mkcls $SRC_DIR/mkcls/mkcls.cpp $SRC_DIR/mkcls/general.cpp $SRC_DIR/mkcls/KategProblemKBC.cpp $SRC_DIR/mkcls/KategProblem.cpp $SRC_DIR/mkcls/Problem.cpp $SRC_DIR/mkcls/ProblemTest.cpp $SRC_DIR/mkcls/IterOptimization.cpp $SRC_DIR/mkcls/StatVar.cpp $SRC_DIR/mkcls/TAOptimization.cpp $SRC_DIR/mkcls/SAOptimization.cpp $SRC_DIR/mkcls/GDAOptimization.cpp $SRC_DIR/mkcls/MYOptimization.cpp $SRC_DIR/mkcls/RRTOptimization.cpp $SRC_DIR/mkcls/HCOptimization.cpp $SRC_DIR/mkcls/Optimization.cpp $SRC_DIR/mkcls/KategProblemWBC.cpp $SRC_DIR/mkcls/KategProblemTest.cpp

#cp $BIN_DIR/mgiza $INSTALL_DIR
#cp $MGIZA_DIR/scripts/*.pl $INSTALL_DIR
#cp $MGIZA_DIR/scripts/*.py $INSTALL_DIR

