using JuMP
using Gurobi

#Sets
Warehouses=["Seattle-S","Denver-S","St.Louis-S","Atlanta-S","Philadelphia-S","Seattle-L","Denver-L","St.Louis-L","Atlanta-L","Philadelphia-L"];
Customers=["Northwest","Southwest","Upper Midwest","Lower Midwest","Northeast","Southeast"];
Periods=["2007","2008","2009","2010","2011"];
Scenarios=["S1","S2","S3","S4","S5"]
I = length(Customers) #No. of zones/customers
J = length(Warehouses) #No. of potential warehouses/DCs
P = length(Periods) #No. of periods
S=length(Scenarios)#No. of scenarios

#Data
h = 
[320000 576000 1036800 1866240 1866240;
200000 360000 648000  1166400 1166400;
160000 288000 518400  933120  933120;
220000 396000 712800  1283040 1283040;
350000 630000 1134000 2041200 2041200;
175000 315000 567000  1020600 1020600]

f = [300000 250000 220000 220000 240000 500000 420000 375000 375000 400000] #Fixed cost of potential warehouses
q = [0.4 0.15 0.15 0.15 0.15]# Probality of scenarios
b = 0.2 #Variable cost of potential warehouses

v = [[2000000 2000000 2000000 2000000 2000000 4000000 4000000 4000000 4000000 4000000],
    [1600000 1600000 1600000 1600000 1600000 3200000 3200000 3200000 3200000 3200000],
    [1500000 1500000 1500000 1500000 1500000 3000000 3000000 3000000 3000000 3000000],
    [1400000 1400000 1400000 1400000 1400000 2800000 2800000 2800000 2800000 2800000],
    [1000000 1000000 1000000 1000000 1000000 2000000 2000000 2000000 2000000 2000000]
] #Capacity of large/small warehouses

c=[
2 2.5 3.5 4 5 5.5;
2.5 2.5 2.5 3 4 4.5;
3.5 3.5 2.5 2.5 3 3.5;
4 4 3 2.5 3 2.5;
4.5 5 3 3.5 2 4;
2 2.5 3.5 4 5 5.5;
2.5 2.5 2.5 3 4 4.5;
3.5 3.5 2.5 2.5 3 3.5;
4 4 3 2.5 3 2.5;
4.5 5 3 3.5 2 4
]

model = Model(Gurobi.Optimizer)
set_optimizer_attribute(model, "NonConvex", 2)

@variable(model, 1 >= x[j=1:J,p=1:P] >= 0);
@variable(model, y[i=1:I,j=1:J,p=1:P,s=1:S] >= 0, Int); 

@objective(model, Min, sum(sum(f[j]*x[j,p] for j=1:J) for p=1:P)
    + sum(sum(sum(sum(b*q[s]*y[i,j,p,s] for i=1:I) for j=1:J) for p=1:P) for s=1:S)
    + sum(sum(sum(sum(((c[j,i]-3)/4)*q[s]*y[i,j,p,s] for i=1:I) for j=1:J) for p=1:P) for s=1:S)
    + sum(sum(475000*x[j,p]+0.165*sum(sum(q[s]*y[i,j,p,s] for i=1:I) for s=1:S) for j=1:J) for p=1:P));

@constraint(model,[i=1:I, p=1:P, s=1:S], sum(y[i,j,p,s] for j=1:J)== h[i,p]);
@constraint(model,[j=1:J, p=1:P, s=1:S], sum(y[i,j,p,s] for i=1:I)<= v[s][j]*x[j,p]);

@constraint(model,[p=1:P,j=1:5], x[j,p] * x[j+5,p] == 0) #large and small warehouses are not open in the same location in certain period


optimize!(model)

if termination_status(model) == MOI.OPTIMAL
    println("RESULTS:")
    println("Objective = $(objective_value(model))")
    for p=1:P
        println("In year ", Periods[p], ":")
        for j=1:J
            if (value(x[j,p])>0) 
                println("Warehouse ", Warehouses[j]," is rented at ", value(x[j,p])*100,"%  level and serves customer: ")
                for s=1:S
                    for i=1:I
                        if (value(y[i,j,p,s]) > 0)
                            println(Customers[i],", Demand satisfied = ",value(y[i,j,p,s])," in Scenario ",Scenarios[s])
                        end
                    end
                end
            end
        end
    end
else
    println("No solution")
end