
A master table is enriched with columns coming from a reference
table.

We want to enrich this table:
| type     | quty |
|----------+------|
| onion    |   70 |
| tomato   |  120 |
| eggplant |  300 |
| tofu     |  100 |

We have a reference table:
| type     | Fiber | Sugar | Protein | Carb |
|----------+-------+-------+---------+------|
| eggplant |   2.5 |   3.2 |     0.8 |  8.6 |
| tomato   |   0.6 |   2.1 |     0.8 |  3.4 |
| onion    |   1.3 |   4.4 |     1.3 |  9.0 |
| egg      |     0 |  18.3 |    31.9 | 18.3 |
| rice     |   0.2 |     0 |     1.5 | 16.0 |
| bread    |   0.7 |   0.7 |     3.3 | 16.0 |
| orange   |   3.1 |  11.9 |     1.3 | 17.6 |
| banana   |   2.1 |   9.9 |     0.9 | 18.5 |
| tofu     |   0.7 |   0.5 |     6.6 |  1.4 |
| nut      |   2.6 |   1.3 |     4.9 |  7.2 |
| corn     |   4.7 |   1.8 |     2.8 | 21.3 |

We get the resulting joined table:
| type     | quty | Fiber | Sugar | Protein | Carb |
|----------+------+-------+-------+---------+------|
| onion    |   70 |   1.3 |   4.4 |     1.3 |  9.0 |
| tomato   |  120 |   0.6 |   2.1 |     0.8 |  3.4 |
| eggplant |  300 |   2.5 |   3.2 |     0.8 |  8.6 |
| tofu     |  100 |   0.7 |   0.5 |     6.6 |  1.4 |

Full documentation here:
  https://github.com/tbanel/orgtbljoin/blob/master/README.org
